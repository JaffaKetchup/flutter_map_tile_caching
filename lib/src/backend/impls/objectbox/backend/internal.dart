// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

/// Internal implementation of [FMTCBackend] that uses ObjectBox as the storage
/// database
abstract interface class FMTCObjectBoxBackendInternal
    implements FMTCBackendInternal {
  static final _instance = _ObjectBoxBackendImpl._();
}

class _ObjectBoxBackendImpl implements FMTCObjectBoxBackendInternal {
  _ObjectBoxBackendImpl._();

  @override
  String get friendlyIdentifier => 'ObjectBox';

  @override
  Directory? rootDirectory;

  void get expectInitialised => _sendPort ?? (throw RootUnavailable());

  // Worker communication protocol storage
  SendPort? _sendPort;
  final _workerResOneShot = <int, Completer<Map<String, dynamic>?>>{};
  final _workerResStreamed = <int, StreamSink<Map<String, dynamic>?>>{};
  int _workerId = 0;
  late Completer<void> _workerComplete;
  late StreamSubscription<dynamic> _workerHandler;

  // `removeOldestTilesAboveLimit` tracking & debouncing
  Timer? _rotalDebouncer;
  String? _rotalStore;

  Future<Map<String, dynamic>?> _sendCmdOneShot({
    required _WorkerCmdType type,
    Map<String, dynamic> args = const {},
  }) async {
    expectInitialised;

    final id = ++_workerId; // Create new unique ID
    _workerResOneShot[id] = Completer(); // Will be completed by direct handler
    _sendPort!.send((id: id, type: type, args: args)); // Send cmd

    try {
      return await _workerResOneShot[id]!.future; // Await response
    } catch (err, stackTrace) {
      Error.throwWithStackTrace(
        err,
        StackTrace.fromString(
          '$stackTrace<asynchronous suspension>\n${StackTrace.current}'
          '#+      [FMTC Debug Info]      $type: $args\n',
        ),
      );
    } finally {
      _workerResOneShot.remove(id); // Free memory
    }
  }

  Stream<Map<String, dynamic>?> _sendCmdStreamed({
    required _WorkerCmdType type,
    Map<String, dynamic> args = const {},
  }) async* {
    expectInitialised;

    final id = ++_workerId; // Create new unique ID
    final controller = StreamController<Map<String, dynamic>?>(
      onCancel: () async {
        _workerResStreamed.remove(id); // Free memory
        // Cancel the worker stream if the worker is alive
        if (!_workerComplete.isCompleted) {
          await _sendCmdOneShot(type: type.streamCancel!, args: {'id': id});
        }
      },
    );
    _workerResStreamed[id] =
        controller.sink; // Will be inserted into by direct handler
    _sendPort!.send((id: id, type: type, args: args)); // Send cmd

    try {
      // Not using yield* as it doesn't allow for correct error handling
      await for (final evt in controller.stream) {
        // Listen to responses
        yield evt;
      }
    } catch (err, stackTrace) {
      yield Error.throwWithStackTrace(
        err,
        StackTrace.fromString(
          '$stackTrace<asynchronous suspension>\n#+      [FMTC]      Unable to '
          'attach final `StackTrace` when streaming results\n<asynchronous '
          'suspension>\n#+      [FMTC]      (Debug Info) $type: $args\n',
        ),
      );
    } finally {
      // Goto `onCancel` once output listening cancelled
      await controller.close();
    }
  }

  Future<void> initialise({
    required String? rootDirectory,
    required int maxDatabaseSize,
    required String? macosApplicationGroup,
  }) async {
    if (_sendPort != null) throw RootAlreadyInitialised();

    this.rootDirectory = await Directory(
      path.join(
        rootDirectory ??
            (await getApplicationDocumentsDirectory()).absolute.path,
        'fmtc',
      ),
    ).create(recursive: true);

    // Prepare to recieve `SendPort` from worker
    _workerResOneShot[0] = Completer();
    final workerInitialRes = _workerResOneShot[0]!
        .future // Completed directly by handler below
        .then<({ByteData? storeRef, Object? err, StackTrace? stackTrace})>(
      (res) {
        _workerResOneShot.remove(0);
        _sendPort = res!['sendPort'];

        return (
          storeRef: res['storeReference'] as ByteData,
          err: null,
          stackTrace: null,
        );
      },
      onError: (err, stackTrace) {
        _workerHandler.cancel();
        _workerComplete.complete();

        _workerId = 0;
        _workerResOneShot.clear();
        _workerResStreamed.clear();

        return (storeRef: null, err: err, stackTrace: stackTrace);
      },
    );

    // Setup worker comms/response handler
    final receivePort = ReceivePort();
    _workerComplete = Completer();
    _workerHandler = receivePort.listen(
      (evt) {
        evt as ({int id, Map<String, dynamic>? data})?;

        // Killed forcefully by environment (eg. hot restart)
        if (evt == null) {
          _workerHandler.cancel(); // Ensure this handler is cancelled on return
          _workerComplete.complete();
          // Doesn't require full cleanup, because hot restart has done that
          return;
        }

        // Handle errors
        final err = evt.data?['error'];
        if (err != null) {
          if (evt.data?['expectStream'] == true) {
            _workerResStreamed[evt.id]!.addError(err, evt.data!['stackTrace']);
          } else {
            _workerResOneShot[evt.id]!
                .completeError(err, evt.data!['stackTrace']);
          }
          return;
        }

        if (evt.data?['expectStream'] == true) {
          _workerResStreamed[evt.id]!.add(evt.data);
        } else {
          _workerResOneShot[evt.id]!.complete(evt.data);
        }
      },
      onDone: () => _workerComplete.complete(),
    );

    // Spawn worker isolate
    await Isolate.spawn(
      _worker,
      (
        sendPort: receivePort.sendPort,
        rootDirectory: this.rootDirectory!,
        maxDatabaseSize: maxDatabaseSize,
        macosApplicationGroup: macosApplicationGroup,
        rootIsolateToken: ServicesBinding.rootIsolateToken!,
      ),
      onExit: receivePort.sendPort,
      debugName: '[FMTC] ObjectBox Backend Worker',
    );

    // Wait for initial response from isolate
    final initResult = await workerInitialRes;

    // Check whether initialisation was successful
    if (initResult.storeRef != null) {
      FMTCBackendAccess.internal = this;
      FMTCBackendAccessThreadSafe.internal = _ObjectBoxBackendThreadSafeImpl._(
        storeReference: initResult.storeRef!,
      );
    } else {
      Error.throwWithStackTrace(initResult.err!, initResult.stackTrace!);
    }
  }

  Future<void> uninitialise({
    required bool deleteRoot,
    required bool immediate,
  }) async {
    expectInitialised;

    // Wait for all currently underway operations to complete before destroying
    // the isolate (if not `immediate`)
    if (!immediate) {
      await Future.wait(_workerResOneShot.values.map((e) => e.future));
    }

    // Send self-destruct cmd to worker, and wait for response and exit
    await _sendCmdOneShot(
      type: _WorkerCmdType.destroy,
      args: {'deleteRoot': deleteRoot},
    );
    await _workerComplete.future;

    // Destroy remaining worker refs
    _sendPort = null; // Indicate ready for re-init
    await _workerHandler.cancel(); // Stop response handler

    // Kill any remaining operations with an error (they'll never recieve a
    // response from the worker)
    for (final completer in _workerResOneShot.values) {
      completer.complete({'error': RootUnavailable()});
    }
    for (final streamController in List.of(_workerResStreamed.values)) {
      await streamController.close();
    }

    // Reset state
    _workerId = 0;
    _workerResOneShot.clear();
    _workerResStreamed.clear();
    _rotalDebouncer?.cancel();
    _rotalDebouncer = null;
    _rotalStore = null;

    FMTCBackendAccess.internal = null;
    FMTCBackendAccessThreadSafe.internal = null;
  }

  @override
  Future<double> realSize() async =>
      (await _sendCmdOneShot(type: _WorkerCmdType.realSize))!['size'];

  @override
  Future<double> rootSize() async =>
      (await _sendCmdOneShot(type: _WorkerCmdType.rootSize))!['size'];

  @override
  Future<int> rootLength() async =>
      (await _sendCmdOneShot(type: _WorkerCmdType.rootLength))!['length'];

  @override
  Future<List<String>> listStores() async =>
      (await _sendCmdOneShot(type: _WorkerCmdType.listStores))!['stores'];

  @override
  Future<bool> storeExists({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.storeExists,
        args: {'storeName': storeName},
      ))!['exists'];

  @override
  Future<void> createStore({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.createStore,
        args: {'storeName': storeName},
      );

  @override
  Future<void> resetStore({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.resetStore,
        args: {'storeName': storeName},
      );

  @override
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.renameStore,
        args: {
          'currentStoreName': currentStoreName,
          'newStoreName': newStoreName,
        },
      );

  @override
  Future<void> deleteStore({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.deleteStore,
        args: {'storeName': storeName},
      );

  @override
  Future<({double size, int length, int hits, int misses})> getStoreStats({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.getStoreStats,
        args: {'storeName': storeName},
      ))!['stats'];

  @override
  Future<bool> tileExistsInStore({
    required String storeName,
    required String url,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.tileExistsInStore,
        args: {'storeName': storeName, 'url': url},
      ))!['exists'];

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
    String? storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.readTile,
        args: {'url': url, 'storeName': storeName},
      ))!['tile'];

  @override
  Future<ObjectBoxTile?> readLatestTile({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.readLatestTile,
        args: {'storeName': storeName},
      ))!['tile'];

  @override
  Future<void> writeTile({
    required String storeName,
    required String url,
    required Uint8List? bytes,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.writeTile,
        args: {'storeName': storeName, 'url': url, 'bytes': bytes},
      );

  @override
  Future<bool?> deleteTile({
    required String storeName,
    required String url,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.deleteStore,
        args: {'storeName': storeName, 'url': url},
      ))!['wasOrphan'];

  @override
  Future<void> registerHitOrMiss({
    required String storeName,
    required bool hit,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.registerHitOrMiss,
        args: {'storeName': storeName, 'hit': hit},
      );

  @override
  Future<int> removeOldestTilesAboveLimit({
    required String storeName,
    required int tilesLimit,
  }) async {
    const type = _WorkerCmdType.removeOldestTilesAboveLimit;
    final args = {'storeName': storeName, 'tilesLimit': tilesLimit};

    // Attempts to avoid flooding worker with requests to delete oldest tile,
    // and 'batches' them instead

    if (_rotalStore != storeName) {
      // If the store has changed, failing to reset the batch/queue will mean
      // tiles are removed from the wrong store
      _rotalStore = storeName;
      if (_rotalDebouncer?.isActive ?? false) {
        _rotalDebouncer!.cancel();
        return (await _sendCmdOneShot(type: type, args: args))!['numOrphans'];
      }
    }

    if (_rotalDebouncer?.isActive ?? false) {
      _rotalDebouncer!.cancel();
      _rotalDebouncer = Timer(
        const Duration(milliseconds: 500),
        () async =>
            (await _sendCmdOneShot(type: type, args: args))!['numOrphans'],
      );
      return -1;
    }

    _rotalDebouncer = Timer(
      const Duration(seconds: 1),
      () async =>
          (await _sendCmdOneShot(type: type, args: args))!['numOrphans'],
    );

    return -1;
  }

  /* FOR ABOVE METHOD
    // Attempts to avoid flooding worker with requests to delete oldest tile,
    // and 'batches' them instead

    if (_dotStore != storeName) {
      // If the store has changed, failing to reset the batch/queue will mean
      // tiles are removed from the wrong store
      _dotStore = storeName;
      if (_dotDebouncer.isActive) {
        _dotDebouncer.cancel();
        _sendROTCmd(storeName);
        _dotLength += numToRemove;
      }
    }

    if (_dotDebouncer.isActive) {
      _dotDebouncer.cancel();
      _dotDebouncer = Timer(
        const Duration(milliseconds: 500),
        () => _sendROTCmd(storeName),
      );
      _dotLength += numToRemove;
      return;
    }

    _dotDebouncer =
        Timer(const Duration(seconds: 1), () => _sendROTCmd(storeName));
    _dotLength += numToRemove;

    // may need to be moved out
     void _sendROTCmd(String storeName) {
      _sendCmd(
        type: _WorkerCmdType.removeOldestTile,
        args: {'storeName': storeName, 'number': _dotLength},
      );
      _dotLength = 0;
    }
    */

  @override
  Future<int> removeTilesOlderThan({
    required String storeName,
    required DateTime expiry,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.removeTilesOlderThan,
        args: {'storeName': storeName, 'expiry': expiry},
      ))!['numOrphans'];

  @override
  Future<Map<String, String>> readMetadata({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.readMetadata,
        args: {'storeName': storeName},
      ))!['metadata'];

  @override
  Future<void> setMetadata({
    required String storeName,
    required String key,
    required String value,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.setMetadata,
        args: {'storeName': storeName, 'key': key, 'value': value},
      );

  @override
  Future<void> setBulkMetadata({
    required String storeName,
    required Map<String, String> kvs,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.setBulkMetadata,
        args: {'storeName': storeName, 'kvs': kvs},
      );

  @override
  Future<String?> removeMetadata({
    required String storeName,
    required String key,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.removeMetadata,
        args: {'storeName': storeName, 'key': key},
      ))!['removedValue'];

  @override
  Future<void> resetMetadata({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.resetMetadata,
        args: {'storeName': storeName},
      );

  @override
  Future<List<RecoveredRegion>> listRecoverableRegions() async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.listRecoverableRegions,
      ))!['recoverableRegions'];

  @override
  Future<RecoveredRegion> getRecoverableRegion({
    required int id,
  }) async =>
      (await _sendCmdOneShot(
        type: _WorkerCmdType.getRecoverableRegion,
      ))!['recoverableRegion'];

  @override
  Future<void> startRecovery({
    required int id,
    required String storeName,
    required DownloadableRegion region,
  }) =>
      _sendCmdOneShot(
        type: _WorkerCmdType.startRecovery,
        args: {'id': id, 'storeName': storeName, 'region': region},
      );

  @override
  Future<void> cancelRecovery({
    required int id,
  }) =>
      _sendCmdOneShot(type: _WorkerCmdType.cancelRecovery, args: {'id': id});

  @override
  Stream<void> watchRecovery({
    required bool triggerImmediately,
  }) =>
      _sendCmdStreamed(
        type: _WorkerCmdType.watchRecovery,
        args: {'triggerImmediately': triggerImmediately},
      );

  @override
  Stream<void> watchStores({
    required List<String> storeNames,
    required bool triggerImmediately,
  }) =>
      _sendCmdStreamed(
        type: _WorkerCmdType.watchStores,
        args: {
          'storeNames': storeNames,
          'triggerImmediately': triggerImmediately,
        },
      );
}
