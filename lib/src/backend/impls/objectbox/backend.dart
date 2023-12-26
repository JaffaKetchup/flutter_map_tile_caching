import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart' as meta;
import 'package:path_provider/path_provider.dart';

import '../../../misc/exts.dart';
import '../../impl_tools/errors.dart';
import '../../impl_tools/no_sync.dart';
import '../../interfaces/backend.dart';
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

class _ObjectBoxBackendImpl
    with FMTCBackendNoSync
    implements ObjectBoxBackendInternal {
  _ObjectBoxBackendImpl._();

  void get expectInitialised => _sendPort ?? (throw RootUnavailable());

  // Worker Comms
  SendPort? _sendPort;
  Completer<void>? _workerCompleter;
  Completer<_WorkerRes>? _workerCmdRes;
  //final _cmdQueue = <_WorkerKey, Completer<_WorkerRes>?>{
  //  for (final v in _WorkerKey.values) v: null,
  //};

  // `deleteOldestTile` tracking & debouncing
  int _dotLength = 0;
  Timer? _dotDebouncer;
  String? _dotStore;

  Future<_WorkerRes> sendCmd(_WorkerCmd cmd) async {
    expectInitialised;

    // If a command is already pending response, wait for it to complete
    await _workerCmdRes?.future;

    _workerCmdRes = Completer();
    _sendPort!.send(cmd);
    final res = await _workerCmdRes!.future;
    _workerCmdRes = null;
    return res;
  }

  Future<void> workerListener(ReceivePort receivePort) async {
    await for (final _WorkerRes evt in receivePort) {
      if (evt.key == _WorkerKey.initialise_) {
        _sendPort = evt.data!['sendPort']! as SendPort;
      } else {
        _workerCmdRes!.complete(evt);
      }
    }
    _workerCompleter!.complete();
  }

  @override
  String get friendlyIdentifier => 'ObjectBox';

  /// {@macro fmtc_backend_initialise}
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

    // Setup worker isolate
    final receivePort = ReceivePort();
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

    _workerCompleter = Completer();
    return;
  }

  @override
  Future<void> destroy({
    bool deleteRoot = false,
  }) async {
    expectInitialised;

    unawaited(
      sendCmd(
        (key: _WorkerKey.destroy_, args: {'deleteRoot': deleteRoot}),
      ),
    );
    await _workerCompleter!.future;
    _sendPort = null;
  }

  @override
  Future<void> createStore({
    required String storeName,
  }) =>
      sendCmd((key: _WorkerKey.createStore, args: {'storeName': storeName}));

  @override
  Future<void> resetStore({
    required String storeName,
  }) =>
      sendCmd((key: _WorkerKey.resetStore, args: {'storeName': storeName}));

  @override
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) =>
      sendCmd(
        (
          key: _WorkerKey.renameStore,
          args: {
            'currentStoreName': currentStoreName,
            'newStoreName': newStoreName,
          }
        ),
      );

  @override
  Future<void> deleteStore({
    required String storeName,
  }) =>
      sendCmd((key: _WorkerKey.deleteStore, args: {'storeName': storeName}));

  @override
  Future<double> getStoreSize({
    required String storeName,
  }) async =>
      (await sendCmd(
        (key: _WorkerKey.getStoreSize, args: {'storeName': storeName}),
      ))
          .data!['size']! as double;

  @override
  Future<int> getStoreLength({
    required String storeName,
  }) async =>
      (await sendCmd(
        (key: _WorkerKey.getStoreLength, args: {'storeName': storeName}),
      ))
          .data!['length']! as int;

  @override
  Future<int> getStoreHits({
    required String storeName,
  }) async =>
      (await sendCmd(
        (key: _WorkerKey.getStoreHits, args: {'storeName': storeName}),
      ))
          .data!['hits']! as int;

  @override
  Future<int> getStoreMisses({
    required String storeName,
  }) async =>
      (await sendCmd(
        (key: _WorkerKey.getStoreMisses, args: {'storeName': storeName}),
      ))
          .data!['misses']! as int;

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
  }) async =>
      (await sendCmd((key: _WorkerKey.readTile, args: {'url': url})))
          .data!['tile'] as ObjectBoxTile?;

  @override
  Future<void> writeTile({
    required String storeName,
    required String url,
    required Uint8List? bytes,
  }) =>
      sendCmd(
        (
          key: _WorkerKey.writeTile,
          args: {'storeName': storeName, 'url': url, 'bytes': bytes}
        ),
      );

  @override
  Future<bool?> deleteTile({
    required String url,
    required String storeName,
  }) async =>
      (await sendCmd(
        (
          key: _WorkerKey.deleteStore,
          args: {'storeName': storeName, 'url': url}
        ),
      ))
          .data!['wasOrphaned'] as bool?;

  void _sendRemoveOldestTileCmd(String storeName) {
    sendCmd(
      (
        key: _WorkerKey.removeOldestTile,
        args: {
          'storeName': storeName,
          'number': _dotLength,
        }
      ),
    );
    _dotLength = 0;
  }

  @override
  void removeOldestTileSync({
    required String storeName,
  }) {
    // Attempts to avoid flooding worker with requests to delete oldest tile,
    // and 'batches' them instead

    if (_dotStore != storeName) {
      // If the store has changed, failing to reset the batch/queue will mean
      // tiles are removed from the wrong store
      _dotStore = storeName;
      if (_dotDebouncer != null && _dotDebouncer!.isActive) {
        _dotDebouncer!.cancel();
        _sendRemoveOldestTileCmd(storeName);
      }
    }

    if (_dotDebouncer != null && _dotDebouncer!.isActive) {
      _dotDebouncer!.cancel();
      _dotDebouncer = Timer(
        const Duration(milliseconds: 500),
        () => _sendRemoveOldestTileCmd(storeName),
      );
      return;
    }

    _dotDebouncer = Timer(
      const Duration(seconds: 1),
      () => _sendRemoveOldestTileCmd(storeName),
    );
  }

  @override
  Future<void> removeOldestTile({
    required String storeName,
  }) async =>
      removeOldestTileSync(storeName: storeName);
}
