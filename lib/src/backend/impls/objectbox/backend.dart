import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart' as meta;
import 'package:path_provider/path_provider.dart';

import '../../../misc/exts.dart';
import '../../interfaces/backend.dart';
import '../../utils/errors.dart';
import 'models/generated/objectbox.g.dart';
import 'models/models.dart';

part 'worker.dart';

final class ObjectBoxBackend implements FMTCBackend {
  @override
  @meta.internal
  FMTCBackendInternal get internal => ObjectBoxBackendInternal._instance;
}

/// Implementation of [FMTCBackend] that uses ObjectBox as the storage database
///
/// Only to be accessed by FMTC via [ObjectBoxBackend.internal]
abstract interface class ObjectBoxBackendInternal
    implements FMTCBackendInternal {
  static final _instance = _ObjectBoxBackendImpl._();
}

class _ObjectBoxBackendImpl implements ObjectBoxBackendInternal {
  _ObjectBoxBackendImpl._();

  void get expectInitialised => _sendPort ?? (throw RootUnavailable());

  // Worker communication
  SendPort? _sendPort;
  final Map<int, Completer<Map<String, dynamic>?>> _workerRes = {};
  late int _workerId;
  late Completer<void> _workerComplete;
  late StreamSubscription<dynamic> _workerHandler;

  // `deleteOldestTile` tracking & debouncing
  late int _dotLength;
  late Timer _dotDebouncer;
  late String? _dotStore;

  Future<Map<String, dynamic>?> _sendCmd({
    required _WorkerCmdType type,
    required Map<String, dynamic> args,
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

  @override
  String get friendlyIdentifier => 'ObjectBox';

  /// {@macro fmtc.backend.initialise}
  ///
  /// This implementation additionally accepts the following [implSpecificArgs]:
  ///
  ///  * 'macosApplicationGroup' (`String`): when creating a sandboxed macOS app,
  /// use to specify the application group (of less than 20 chars). See
  /// [the ObjectBox docs](https://docs.objectbox.io/getting-started) for
  /// details.
  ///  * 'maxReaders' (`int`): for debugging purposes only
  ///
  /// These arguments are optional. However, failure to provide them in the
  /// specified type will result in an uncaught type casting error.
  @override
  Future<void> initialise({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  }) async {
    if (_sendPort != null) throw RootAlreadyInitialised();

    // Reset non-comms-related non-resource-intensive state
    _workerId = 0;
    _workerRes.clear();
    _dotStore = null;
    _dotLength = 0;

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
        rootDirectory: rootDirectory,
        maxDatabaseSize: maxDatabaseSize,
        macosApplicationGroup:
            implSpecificArgs['macosApplicationGroup']! as String,
        maxReaders: implSpecificArgs['maxReaders']! as int,
      ),
      onExit: receivePort.sendPort,
      debugName: '[FMTC] ObjectBox Backend Worker',
    );
  }

  @override
  Future<void> destroy({
    bool deleteRoot = false,
    bool immediate = false,
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
    _dotDebouncer.cancel();

    print('passed _workerHandler cancel');

    // Kill any remaining operations with an error (they'll never recieve a
    // response from the worker)
    for (final completer in _workerRes.values) {
      completer.complete({'error': RootUnavailable()});
    }
  }

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
  Future<double> getStoreSize({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.getStoreSize,
        args: {'storeName': storeName},
      ))!['size'];

  @override
  Future<int> getStoreLength({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.getStoreLength,
        args: {'storeName': storeName},
      ))!['length'];

  @override
  Future<int> getStoreHits({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.getStoreHits,
        args: {'storeName': storeName},
      ))!['hits'];

  @override
  Future<int> getStoreMisses({
    required String storeName,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.getStoreMisses,
        args: {'storeName': storeName},
      ))!['misses']! as int;

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
  }) async =>
      (await _sendCmd(
        type: _WorkerCmdType.readTile,
        args: {'url': url},
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
      ))!['wasOrphaned'];

  @override
  Future<void> removeOldestTile({
    required String storeName,
    required int numToRemove,
  }) async {
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
  }

  void _sendROTCmd(String storeName) {
    _sendCmd(
      type: _WorkerCmdType.removeOldestTile,
      args: {'storeName': storeName, 'number': _dotLength},
    );
    _dotLength = 0;
  }
}
