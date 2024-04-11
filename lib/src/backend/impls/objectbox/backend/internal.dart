// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

/// Internal implementation of [FMTCBackend] that uses ObjectBox as the storage
/// database
///
/// Actual implementation performed by `_worker` via `_ObjectBoxBackendImpl`.
abstract interface class FMTCObjectBoxBackendInternal
    implements FMTCBackendInternal {
  static final _instance = _ObjectBoxBackendImpl._();
}

class _ObjectBoxBackendImpl implements FMTCObjectBoxBackendInternal {
  _ObjectBoxBackendImpl._();

  @override
  String get friendlyIdentifier => 'ObjectBox';

  void get expectInitialised => _sendPort ?? (throw RootUnavailable());

  late String rootDirectory;

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
  Completer<int>? _rotalResultCompleter;

  // Define communicators

  Future<Map<String, dynamic>?> _sendCmdOneShot({
    required _CmdType type,
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
    required _CmdType type,
    Map<String, dynamic> args = const {},
  }) async* {
    expectInitialised;

    final id = ++_workerId; // Create new unique ID
    final controller = StreamController<Map<String, dynamic>?>(
      onCancel: () async {
        _workerResStreamed.remove(id); // Free memory
        // Cancel the worker stream if the worker is alive
        if ((type.hasInternalStreamSub ?? false) &&
            !_workerComplete.isCompleted) {
          await _sendCmdOneShot(
            type: _CmdType.cancelInternalStreamSub,
            args: {'id': id},
          );
        }
      },
    );
    _workerResStreamed[id] =
        controller.sink; // Will be inserted into by direct handler
    _sendPort!.send((id: id, type: type, args: args)); // Send cmd

    try {
      // Not using yield* as it doesn't allow for correct error handling
      // (because result must be 'evaluated' here, instead of a direct
      // passthrough)
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

  // Lifecycle implementations

  Future<void> initialise({
    required String? rootDirectory,
    required int maxDatabaseSize,
    required String? macosApplicationGroup,
    required bool useInMemoryDatabase,
  }) async {
    if (_sendPort != null) throw RootAlreadyInitialised();

    if (useInMemoryDatabase) {
      this.rootDirectory = Store.inMemoryPrefix + (rootDirectory ?? 'fmtc');
    } else {
      await Directory(
        this.rootDirectory = path.join(
          rootDirectory ??
              (await getApplicationDocumentsDirectory()).absolute.path,
          'fmtc',
        ),
      ).create(recursive: true);
    }

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

        final isStreamedResult = evt.data?['expectStream'] == true;

        // Handle errors
        if (evt.data?['error'] case final err?) {
          final stackTrace = evt.data!['stackTrace'];
          if (isStreamedResult) {
            _workerResStreamed[evt.id]?.addError(err, stackTrace);
          } else {
            _workerResOneShot[evt.id]!.completeError(err, stackTrace);
          }
          return;
        }

        if (isStreamedResult) {
          // May be `null` if cmd was streamed result, but has no way to prevent
          // future results even after the listener has stopped
          //
          // See `_WorkerCmdType.hasInternalStreamSub` for info.
          _workerResStreamed[evt.id]?.add(evt.data);
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
        rootDirectory: this.rootDirectory,
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
    if (initResult.storeRef case final storeRef?) {
      FMTCBackendAccess.internal = this;
      FMTCBackendAccessThreadSafe.internal =
          _ObjectBoxBackendThreadSafeImpl._(storeReference: storeRef);
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
      type: _CmdType.destroy,
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
    _rotalResultCompleter?.completeError(RootUnavailable());
    _rotalResultCompleter = null;

    FMTCBackendAccess.internal = null;
    FMTCBackendAccessThreadSafe.internal = null;
  }

  // Implementation & worker connectors

  @override
  Future<double> realSize() async =>
      (await _sendCmdOneShot(type: _CmdType.realSize))!['size'];

  @override
  Future<double> rootSize() async =>
      (await _sendCmdOneShot(type: _CmdType.rootSize))!['size'];

  @override
  Future<int> rootLength() async =>
      (await _sendCmdOneShot(type: _CmdType.rootLength))!['length'];

  @override
  Future<List<String>> listStores() async =>
      (await _sendCmdOneShot(type: _CmdType.listStores))!['stores'];

  @override
  Future<bool> storeExists({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.storeExists,
        args: {'storeName': storeName},
      ))!['exists'];

  @override
  Future<void> createStore({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.createStore,
        args: {'storeName': storeName},
      );

  @override
  Future<void> resetStore({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.resetStore,
        args: {'storeName': storeName},
      );

  @override
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.renameStore,
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
        type: _CmdType.deleteStore,
        args: {'storeName': storeName},
      );

  @override
  Future<({double size, int length, int hits, int misses})> getStoreStats({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.getStoreStats,
        args: {'storeName': storeName},
      ))!['stats'];

  @override
  Future<bool> tileExistsInStore({
    required String storeName,
    required String url,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.tileExistsInStore,
        args: {'storeName': storeName, 'url': url},
      ))!['exists'];

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
    String? storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.readTile,
        args: {'url': url, 'storeName': storeName},
      ))!['tile'];

  @override
  Future<ObjectBoxTile?> readLatestTile({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.readLatestTile,
        args: {'storeName': storeName},
      ))!['tile'];

  @override
  Future<void> writeTile({
    required String storeName,
    required String url,
    required Uint8List bytes,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.writeTile,
        args: {'storeName': storeName, 'url': url, 'bytes': bytes},
      );

  @override
  Future<bool?> deleteTile({
    required String storeName,
    required String url,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.deleteTile,
        args: {'storeName': storeName, 'url': url},
      ))!['wasOrphan'];

  @override
  Future<void> registerHitOrMiss({
    required String storeName,
    required bool hit,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.registerHitOrMiss,
        args: {'storeName': storeName, 'hit': hit},
      );

  @override
  Future<int> removeOldestTilesAboveLimit({
    required String storeName,
    required int tilesLimit,
  }) async {
    // By sharing a single completer, all invocations of this method during the
    // debounce period will return the same result at the same time
    if (_rotalResultCompleter?.isCompleted ?? true) {
      _rotalResultCompleter = Completer<int>();
    }
    void sendCmdAndComplete() => _rotalResultCompleter!.complete(
          _sendCmdOneShot(
            type: _CmdType.removeOldestTilesAboveLimit,
            args: {'storeName': storeName, 'tilesLimit': tilesLimit},
          ).then((v) => v!['numOrphans']),
        );

    // If the store has changed, failing to reset the batch/queue will mean
    // tiles are removed from the wrong store
    if (_rotalStore != storeName) {
      _rotalStore = storeName;
      if (_rotalDebouncer?.isActive ?? false) {
        _rotalDebouncer!.cancel();
        sendCmdAndComplete();
        return _rotalResultCompleter!.future;
      }
    }

    // If the timer is already running, debouncing is required: cancel the
    // current timer, and start a new one with a shorter timeout
    final isAlreadyActive = _rotalDebouncer?.isActive ?? false;
    if (isAlreadyActive) _rotalDebouncer!.cancel();
    _rotalDebouncer = Timer(
      Duration(milliseconds: isAlreadyActive ? 500 : 1000),
      sendCmdAndComplete,
    );

    return _rotalResultCompleter!.future;
  }

  @override
  Future<int> removeTilesOlderThan({
    required String storeName,
    required DateTime expiry,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.removeTilesOlderThan,
        args: {'storeName': storeName, 'expiry': expiry},
      ))!['numOrphans'];

  @override
  Future<Map<String, String>> readMetadata({
    required String storeName,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.readMetadata,
        args: {'storeName': storeName},
      ))!['metadata'];

  @override
  Future<void> setMetadata({
    required String storeName,
    required String key,
    required String value,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.setMetadata,
        args: {'storeName': storeName, 'key': key, 'value': value},
      );

  @override
  Future<void> setBulkMetadata({
    required String storeName,
    required Map<String, String> kvs,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.setBulkMetadata,
        args: {'storeName': storeName, 'kvs': kvs},
      );

  @override
  Future<String?> removeMetadata({
    required String storeName,
    required String key,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.removeMetadata,
        args: {'storeName': storeName, 'key': key},
      ))!['removedValue'];

  @override
  Future<void> resetMetadata({
    required String storeName,
  }) =>
      _sendCmdOneShot(
        type: _CmdType.resetMetadata,
        args: {'storeName': storeName},
      );

  @override
  Future<List<RecoveredRegion>> listRecoverableRegions() async =>
      (await _sendCmdOneShot(
        type: _CmdType.listRecoverableRegions,
      ))!['recoverableRegions'];

  @override
  Future<RecoveredRegion> getRecoverableRegion({
    required int id,
  }) async =>
      (await _sendCmdOneShot(
        type: _CmdType.getRecoverableRegion,
      ))!['recoverableRegion'];

  @override
  Future<void> cancelRecovery({
    required int id,
  }) =>
      _sendCmdOneShot(type: _CmdType.cancelRecovery, args: {'id': id});

  @override
  Stream<void> watchRecovery({
    required bool triggerImmediately,
  }) =>
      _sendCmdStreamed(
        type: _CmdType.watchRecovery,
        args: {'triggerImmediately': triggerImmediately},
      );

  @override
  Stream<void> watchStores({
    required List<String> storeNames,
    required bool triggerImmediately,
  }) =>
      _sendCmdStreamed(
        type: _CmdType.watchStores,
        args: {
          'storeNames': storeNames,
          'triggerImmediately': triggerImmediately,
        },
      );

  @override
  Future<void> exportStores({
    required List<String> storeNames,
    required String path,
  }) async {
    if (storeNames.isEmpty) {
      throw ArgumentError.value(storeNames, 'storeNames', 'must not be empty');
    }

    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      throw ImportExportPathNotFile();
    }

    await _sendCmdOneShot(
      type: _CmdType.exportStores,
      args: {'storeNames': storeNames, 'outputPath': path},
    );
  }

  @override
  ImportResult importStores({
    required String path,
    required ImportConflictStrategy strategy,
    required List<String>? storeNames,
  }) {
    Stream<Map<String, dynamic>?> checkTypeAndStartImport() async* {
      await _checkImportPathType(path);
      yield* _sendCmdStreamed(
        type: _CmdType.importStores,
        args: {'path': path, 'strategy': strategy, 'stores': storeNames},
      );
    }

    final storesToStates = Completer<StoresToStates>();
    final complete = Completer<int>();

    late final StreamSubscription<Map<String, dynamic>?> listener;
    listener = checkTypeAndStartImport().listen(
      (evt) {
        if (evt!.containsKey('storesToStates')) {
          storesToStates.complete(evt['storesToStates']);
        }
        if (evt.containsKey('complete')) {
          complete.complete(evt['complete']);
          listener.cancel();
        }
      },
      cancelOnError: true,
    );

    return (
      storesToStates: storesToStates.future,
      complete: complete.future,
    );
  }

  @override
  Future<List<String>> listImportableStores({
    required String path,
  }) async {
    await _checkImportPathType(path);

    return (await _sendCmdOneShot(
      type: _CmdType.listImportableStores,
      args: {'path': path},
    ))!['stores'];
  }

  Future<void> _checkImportPathType(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.notFound) {
      throw ImportPathNotExists(path: path);
    }
    if (type == FileSystemEntityType.directory) {
      throw ImportExportPathNotFile();
    }
  }
}
