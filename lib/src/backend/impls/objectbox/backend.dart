// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../export_internal.dart';
import 'models/generated/objectbox.g.dart';
import 'models/models.dart';

part 'worker.dart';

/// Implementation of [FMTCBackend] that uses ObjectBox as the storage database
final class FMTCObjectBoxBackend implements FMTCBackend {
  /// {@macro fmtc.backend.inititialise}
  ///
  /// [maxDatabaseSize] is the maximum size the database file can grow
  /// to, in KB. Exceeding it throws [DbFullException]. Defaults to 10 GB.
  ///
  /// [macosApplicationGroup] should be set when creating a sandboxed macOS app,
  /// specify the application group (of less than 20 chars). See
  /// [the ObjectBox docs](https://docs.objectbox.io/getting-started) for
  /// details.
  @override
  Future<void> initialise({
    String? rootDirectory,
    int maxDatabaseSize = 10000000,
    String? macosApplicationGroup,
  }) =>
      FMTCObjectBoxBackendInternal._instance.initialise(
        rootDirectory: rootDirectory,
        maxDatabaseSize: maxDatabaseSize,
        macosApplicationGroup: macosApplicationGroup,
      );

  /// {@macro fmtc.backend.uninitialise}
  ///
  /// If [immediate] is `true`, any operations currently underway will be lost.
  /// If `false`, all operations currently underway will be allowed to complete,
  /// but any operations started after this method call will be lost. A lost
  /// operation may throw [RootUnavailable]. This parameter may not have a
  /// noticable/any effect in some implementations.
  @override
  Future<void> uninitialise({
    bool deleteRoot = false,
    bool immediate = false,
  }) =>
      FMTCObjectBoxBackendInternal._instance
          .uninitialise(deleteRoot: deleteRoot, immediate: immediate);
}

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

  void get expectInitialised => _sendPort ?? (throw RootUnavailable());

  @override
  Directory? rootDirectory;

  // Worker communication
  SendPort? _sendPort;
  final Map<int, Completer<Map<String, dynamic>?>> _workerRes = {};
  late int _workerId;
  late Completer<void> _workerComplete;
  late StreamSubscription<dynamic> _workerHandler;

  // TODO: Verify if necessary and remove if not
  //`removeOldestTilesAboveLimit` tracking & debouncing
  //late int _rotalLength;
  //late Timer _rotalDebouncer;
  //late String? _rotalStore;

  Future<Map<String, dynamic>?> _sendCmd({
    required _WorkerCmdType type,
    Map<String, dynamic> args = const {},
  }) async {
    expectInitialised;

    final id = ++_workerId;
    _workerRes[id] = Completer();
    _sendPort!.send((id: id, type: type, args: args));
    final res = await _workerRes[id]!.future;
    _workerRes.remove(id);

    final err = res?['error'];
    if (err == null) return res;

    if (err is FMTCBackendError) throw err;
    debugPrint('An unexpected error in the FMTC backend occurred:');
    // ignore: only_throw_errors
    throw err;
  }

  Future<void> initialise({
    required String? rootDirectory,
    required int maxDatabaseSize,
    required String? macosApplicationGroup,
  }) async {
    if (_sendPort != null) throw RootAlreadyInitialised();

    // Reset non-comms-related non-resource-intensive state
    _workerId = 0;
    _workerRes.clear();
    //_rotalStore = null;
    //_rotalLength = 0;

    this.rootDirectory = await (rootDirectory == null
            ? await getApplicationDocumentsDirectory()
            : Directory(path.join(rootDirectory, 'fmtc')))
        .create(recursive: true);

    // Prepare to recieve `SendPort` from worker
    _workerRes[0] = Completer();
    unawaited(
      _workerRes[0]!.future.then((res) {
        _sendPort = res!['sendPort'];
        _workerRes.remove(0);
      }),
    );

    // Setup worker comms/response handler
    final receivePort = ReceivePort();
    _workerComplete = Completer();
    _workerHandler = receivePort.listen(
      (evt) {
        evt as ({int id, Map<String, dynamic>? data});
        _workerRes[evt.id]!.complete(evt.data);
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
      ),
      onExit: receivePort.sendPort,
      debugName: '[FMTC] ObjectBox Backend Worker',
    );

    FMTCBackendAccess.internal = this;
  }

  Future<void> uninitialise({
    required bool deleteRoot,
    required bool immediate,
  }) async {
    expectInitialised;

    // Wait for all currently underway operations to complete before destroying
    // the isolate (if not `immediate`)
    if (!immediate) await Future.wait(_workerRes.values.map((e) => e.future));

    // Send self-destruct cmd to worker, and don't wait for any response
    unawaited(
      _sendCmd(
        type: _WorkerCmdType.destroy_,
        args: {'deleteRoot': deleteRoot},
      ),
    );

    // Wait for worker to exit (worker handler will exit and signal)
    await _workerComplete.future;

    // Resource-intensive state cleanup only (other cleanup done during init)
    _sendPort = null; // Indicate ready for re-init
    await _workerHandler.cancel();
    //_rotalDebouncer.cancel();

    print('passed _workerHandler cancel');

    // Kill any remaining operations with an error (they'll never recieve a
    // response from the worker)
    for (final completer in _workerRes.values) {
      completer.complete({'error': RootUnavailable()});
    }

    FMTCBackendAccess.internal = null;
  }

  @override
  Future<List<String>> listStores() async =>
      (await _sendCmd(type: _WorkerCmdType.storeExists))!['stores'];

  @override
  Future<double> rootSize() async =>
      (await _sendCmd(type: _WorkerCmdType.rootSize))!['size'];

  @override
  Future<int> rootLength() async =>
      (await _sendCmd(type: _WorkerCmdType.rootLength))!['length'];

  @override
  Future<bool> storeExists({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.storeExists,
        args: {'storeName': storeName},
      ))!['exists'];

  @override
  Future<void> createStore({
    required String storeName,
  }) =>
      _sendCmd(
        type: _WorkerCmdType.createStore,
        args: {'storeName': storeName},
      );

  @override
  Future<void> resetStore({
    required String storeName,
  }) =>
      _sendCmd(
        type: _WorkerCmdType.resetStore,
        args: {'storeName': storeName},
      );

  @override
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) =>
      _sendCmd(
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
      _sendCmd(
        type: _WorkerCmdType.deleteStore,
        args: {'storeName': storeName},
      );

  @override
  Future<({double size, int length, int hits, int misses})> getStoreStats({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.getStoreStats,
        args: {'storeName': storeName},
      ))!['store'];

  @override
  Future<bool> tileExistsInStore({
    required String storeName,
    required String url,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.tileExistsInStore,
        args: {'storeName': storeName, 'url': url},
      ))!['exists'];

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.readTile,
        args: {'url': url},
      ))!['tile'];

  @override
  Future<ObjectBoxTile?> readLatestTile({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.readLatestTile,
        args: {'storeName': storeName},
      ))!['tile'];

  @override
  Future<void> writeTile({
    required String storeName,
    required String url,
    required Uint8List? bytes,
  }) =>
      _sendCmd(
        type: _WorkerCmdType.writeTile,
        args: {'storeName': storeName, 'url': url, 'bytes': bytes},
      );

  @override
  Future<bool?> deleteTile({
    required String url,
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.deleteStore,
        args: {'storeName': storeName, 'url': url},
      ))!['wasOrphan'];

  @override
  Future<int> removeOldestTilesAboveLimit({
    required String storeName,
    required int tilesLimit,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.removeOldestTilesAboveLimit,
        args: {'storeName': storeName, 'tilesLimit': tilesLimit},
      ))!['numOrphans'];

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
      (await _sendCmd(
        type: _WorkerCmdType.removeTilesOlderThan,
        args: {'storeName': storeName, 'expiry': expiry},
      ))!['numOrphans'];

  @override
  Future<Map<String, String>> readMetadata({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.readMetadata,
        args: {'storeName': storeName},
      ))!['metadata'];

  @override
  Future<void> setMetadata({
    required String storeName,
    required String key,
    required String value,
  }) =>
      _sendCmd(
        type: _WorkerCmdType.setMetadata,
        args: {'storeName': storeName, 'key': key, 'value': value},
      );

  @override
  Future<void> setBulkMetadata({
    required String storeName,
    required Map<String, String> kvs,
  }) =>
      _sendCmd(
        type: _WorkerCmdType.setBulkMetadata,
        args: {'storeName': storeName, 'kvs': kvs},
      );

  @override
  Future<String?> removeMetadata({
    required String storeName,
    required String key,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.removeMetadata,
        args: {'storeName': storeName, 'key': key},
      ))!['removedValue'];

  @override
  Future<void> resetMetadata({
    required String storeName,
  }) =>
      _sendCmd(
        type: _WorkerCmdType.resetMetadata,
        args: {'storeName': storeName},
      );
}
