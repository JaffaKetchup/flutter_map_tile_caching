// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

enum _WorkerCmdType {
  initialise_, // Only valid as a request
  destroy,
  realSize,
  rootSize,
  rootLength,
  listStores,
  storeExists,
  createStore,
  resetStore,
  renameStore,
  deleteStore,
  getStoreStats,
  tileExistsInStore,
  readTile,
  readLatestTile,
  writeTile,
  deleteTile,
  registerHitOrMiss,
  removeOldestTilesAboveLimit,
  removeTilesOlderThan,
  readMetadata,
  setMetadata,
  setBulkMetadata,
  removeMetadata,
  resetMetadata,
  listRecoverableRegions,
  getRecoverableRegion,
  startRecovery,
  cancelRecovery,
  watchRecovery(streamCancel: cancelWatch),
  watchStores(streamCancel: cancelWatch),
  cancelWatch;

  const _WorkerCmdType({this.streamCancel});

  /// Command to execute when cancelling a streamed result
  final _WorkerCmdType? streamCancel;
}

Future<void> _worker(
  ({
    SendPort sendPort,
    Directory rootDirectory,
    int maxDatabaseSize,
    String? macosApplicationGroup,
    RootIsolateToken rootIsolateToken,
  }) input,
) async {
  //! SETUP !//

  // Setup comms
  final receivePort = ReceivePort();
  void sendRes({required int id, Map<String, dynamic>? data}) =>
      input.sendPort.send((id: id, data: data));

  // Enable ObjectBox usage from this background isolate
  BackgroundIsolateBinaryMessenger.ensureInitialized(input.rootIsolateToken);

  // Open database, kill self if failed
  late final Store root;
  try {
    root = await openStore(
      directory: input.rootDirectory.absolute.path,
      maxDBSizeInKB: input.maxDatabaseSize, // Defaults to 10 GB
      macosApplicationGroup: input.macosApplicationGroup,
    );

    // If the database is new, create the root statistics object
    final rootBox = root.box<ObjectBoxRoot>();
    if (!rootBox.contains(1)) {
      rootBox.put(ObjectBoxRoot(length: 0, size: 0), mode: PutMode.insert);
    }
  } catch (e, s) {
    sendRes(id: 0, data: {'error': e, 'stackTrace': s});
    Isolate.exit();
  }

  // Create memory for streamed output subscription storage
  final streamedOutputSubscriptions = <int, StreamSubscription>{};

  // Respond with comms channel for future cmds
  sendRes(
    id: 0,
    data: {'sendPort': receivePort.sendPort, 'storeReference': root.reference},
  );

  //! UTIL METHODS !//

  /// Update the root statistics object (ID 0) with the existing values plus
  /// the specified values respectively
  ///
  /// Should be run within a transaction.
  ///
  /// Specified values may be negative.
  ///
  /// Handles cases where there is no root statistics object yet.
  void updateRootStatistics({int deltaLength = 0, int deltaSize = 0}) =>
      root.box<ObjectBoxRoot>().put(
            root.box<ObjectBoxRoot>().get(1)!
              ..length += deltaLength
              ..size += deltaSize,
            mode: PutMode.update,
          );

  /// Delete the specified tiles from the specified store
  ///
  /// Note that [tilesQuery] is not closed internally. Ensure it is closed after
  /// usage.
  ///
  /// Note that a transaction is used internally as necessary.
  ///
  /// Returns the number of orphaned (deleted) tiles.
  int deleteTiles({
    required String storeName,
    required Query<ObjectBoxTile> tilesQuery,
  }) {
    final stores = root.box<ObjectBoxStore>();
    final tiles = root.box<ObjectBoxTile>();

    final storeQuery =
        stores.query(ObjectBoxStore_.name.equals(storeName)).build();

    int rootDeltaLength = 0;
    int rootDeltaSize = 0;

    root.runInTransaction(
      TxMode.write,
      () {
        final queriedTiles = tilesQuery.find();
        final store = storeQuery.findUnique() ??
            (throw StoreNotExists(storeName: storeName));

        for (final tile in queriedTiles) {
          // Modify current store
          store
            ..length -= 1
            ..size -= tile.bytes.lengthInBytes;

          // Remove the store relation from the tile
          tile.stores.removeWhere((store) => store.name == storeName);

          // Delete the tile if it is now orphaned
          if (tile.stores.isEmpty) {
            rootDeltaLength -= 1;
            rootDeltaSize -= tile.bytes.lengthInBytes;
            tiles.remove(tile.id);
            continue;
          }

          // Otherwise apply the new relation
          tile.stores.applyToDb(mode: PutMode.update);
        }

        updateRootStatistics(
          deltaLength: rootDeltaLength,
          deltaSize: rootDeltaSize,
        );
        stores.put(store, mode: PutMode.update);
      },
    );

    storeQuery.close();

    return rootDeltaLength.abs();
  }

  //! MAIN LOOP !//

  await receivePort.listen((cmd) {
    cmd as ({
      int id,
      _WorkerCmdType type,
      Map<String, dynamic> args,
    });

    try {
      switch (cmd.type) {
        case _WorkerCmdType.initialise_:
          throw UnsupportedError('Invalid operation');
        case _WorkerCmdType.destroy:
          root.close();

          if (cmd.args['deleteRoot'] == true) {
            input.rootDirectory.deleteSync(recursive: true);
          }

          sendRes(id: cmd.id);

          Isolate.exit();
        case _WorkerCmdType.realSize:
          sendRes(
            id: cmd.id,
            data: {
              'size': Store.dbFileSize(input.rootDirectory.absolute.path) /
                  1024, // Convert to KiB
            },
          );
        case _WorkerCmdType.rootSize:
          sendRes(
            id: cmd.id,
            data: {'size': root.box<ObjectBoxRoot>().get(1)!.size / 1024},
          );
        case _WorkerCmdType.rootLength:
          sendRes(
            id: cmd.id,
            data: {'length': root.box<ObjectBoxRoot>().get(1)!.length},
          );
        case _WorkerCmdType.listStores:
          final query = root
              .box<ObjectBoxStore>()
              .query()
              .build()
              .property(ObjectBoxStore_.name);

          sendRes(id: cmd.id, data: {'stores': query.find()});

          query.close();
        case _WorkerCmdType.storeExists:
          final query = root
              .box<ObjectBoxStore>()
              .query(
                ObjectBoxStore_.name.equals(cmd.args['storeName']! as String),
              )
              .build();

          sendRes(id: cmd.id, data: {'exists': query.count() == 1});

          query.close();
        case _WorkerCmdType.getStoreStats:
          final storeName = cmd.args['storeName']! as String;

          final query = root
              .box<ObjectBoxStore>()
              .query(ObjectBoxStore_.name.equals(storeName))
              .build();

          final store = query.findUnique() ??
              (throw StoreNotExists(storeName: storeName));

          sendRes(
            id: cmd.id,
            data: {
              'stats': (
                size: store.size / 1024, // Convert to KiB
                length: store.length,
                hits: store.hits,
                misses: store.misses,
              ),
            },
          );

          query.close();
        case _WorkerCmdType.createStore:
          final storeName = cmd.args['storeName']! as String;

          try {
            root.box<ObjectBoxStore>().put(
                  ObjectBoxStore(
                    name: storeName,
                    length: 0,
                    size: 0,
                    hits: 0,
                    misses: 0,
                    metadataJson: '',
                  ),
                  mode: PutMode.insert,
                );
          } on UniqueViolationException {
            sendRes(id: cmd.id);
            break;
          }

          sendRes(id: cmd.id);
        case _WorkerCmdType.resetStore:
          final storeName = cmd.args['storeName']! as String;

          final tiles = root.box<ObjectBoxTile>();
          final stores = root.box<ObjectBoxStore>();

          final tilesQuery = (tiles.query()
                ..linkMany(
                  ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName),
                ))
              .build();

          final storeQuery =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          root.runInTransaction(
            TxMode.write,
            () {
              deleteTiles(storeName: storeName, tilesQuery: tilesQuery);

              final store = storeQuery.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              storeQuery.close();

              stores.put(
                store
                  ..length = 0
                  ..size = 0
                  ..hits = 0
                  ..misses = 0,
                mode: PutMode.update,
              );
            },
          );

          sendRes(id: cmd.id);
        case _WorkerCmdType.renameStore:
          final currentStoreName = cmd.args['currentStoreName']! as String;
          final newStoreName = cmd.args['newStoreName']! as String;

          final stores = root.box<ObjectBoxStore>();

          final query = stores
              .query(ObjectBoxStore_.name.equals(currentStoreName))
              .build();

          root.runInTransaction(
            TxMode.write,
            () {
              final store = query.findUnique() ??
                  (throw StoreNotExists(storeName: currentStoreName));
              query.close();

              stores.put(store..name = newStoreName, mode: PutMode.update);
            },
          );

          sendRes(id: cmd.id);
        case _WorkerCmdType.deleteStore:
          final storeName = cmd.args['storeName']! as String;

          final storesQuery = root
              .box<ObjectBoxStore>()
              .query(ObjectBoxStore_.name.equals(storeName))
              .build();
          final tilesQuery = (root.box<ObjectBoxTile>().query()
                ..linkMany(
                  ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName),
                ))
              .build();

          root.runInTransaction(
            TxMode.write,
            () {
              deleteTiles(storeName: storeName, tilesQuery: tilesQuery);
              storesQuery.remove();
            },
          );

          sendRes(id: cmd.id);

          storesQuery.close();
          tilesQuery.close();
        case _WorkerCmdType.tileExistsInStore:
          final storeName = cmd.args['storeName']! as String;
          final url = cmd.args['url']! as String;

          final query =
              (root.box<ObjectBoxTile>().query(ObjectBoxTile_.url.equals(url))
                    ..linkMany(
                      ObjectBoxTile_.stores,
                      ObjectBoxStore_.name.equals(storeName),
                    ))
                  .build();

          sendRes(id: cmd.id, data: {'exists': query.count() == 1});

          query.close();
        case _WorkerCmdType.readTile:
          final url = cmd.args['url']! as String;
          final storeName = cmd.args['storeName'] as String?;

          final stores = root.box<ObjectBoxTile>();

          final query = storeName == null
              ? stores.query(ObjectBoxTile_.url.equals(url)).build()
              : (stores.query(ObjectBoxTile_.url.equals(url))
                    ..linkMany(
                      ObjectBoxTile_.stores,
                      ObjectBoxStore_.name.equals(storeName),
                    ))
                  .build();

          sendRes(id: cmd.id, data: {'tile': query.findUnique()});

          query.close();
        case _WorkerCmdType.readLatestTile:
          final storeName = cmd.args['storeName']! as String;

          final query = (root
                  .box<ObjectBoxTile>()
                  .query()
                  .order(ObjectBoxTile_.lastModified, flags: Order.descending)
                ..linkMany(
                  ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName),
                ))
              .build();

          sendRes(id: cmd.id, data: {'tile': query.findFirst()});

          query.close();
        case _WorkerCmdType.writeTile:
          // TODO: Test all
          final storeName = cmd.args['storeName']! as String;
          final url = cmd.args['url']! as String;
          final bytes = cmd.args['bytes'] as Uint8List?;

          final tiles = root.box<ObjectBoxTile>();
          final stores = root.box<ObjectBoxStore>();

          final tilesQuery =
              tiles.query(ObjectBoxTile_.url.equals(url)).build();
          final storeQuery =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          root.runInTransaction(
            TxMode.write,
            () {
              final existingTile = tilesQuery.findUnique();

              final store = storeQuery.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));

              switch ((existingTile == null, bytes == null)) {
                case (true, false): // No existing tile
                  tiles.put(
                    ObjectBoxTile(
                      url: url,
                      lastModified: DateTime.timestamp(),
                      bytes: bytes!,
                    )..stores.add(store),
                  );
                  stores.put(
                    store
                      ..length += 1
                      ..size += bytes.lengthInBytes,
                  );
                  updateRootStatistics(
                    deltaLength: 1,
                    deltaSize: bytes.lengthInBytes,
                  );
                case (false, true): // Existing tile, no update
                  // Only take action if it's not already belonging to the store
                  if (!existingTile!.stores.contains(store)) {
                    tiles.put(existingTile..stores.add(store));
                    stores.put(
                      store
                        ..length += 1
                        ..size += existingTile.bytes.lengthInBytes,
                    );
                    updateRootStatistics(
                      deltaLength: 1,
                      deltaSize: existingTile.bytes.lengthInBytes,
                    );
                  }
                case (false, false): // Existing tile, update required
                  int rootDeltaSize = 0;
                  tiles.put(
                    existingTile!
                      ..lastModified = DateTime.timestamp()
                      ..bytes = bytes!,
                    mode: PutMode.update,
                  );
                  stores.putMany(
                    existingTile.stores.map(
                      (store) {
                        final diff = bytes.lengthInBytes -
                            existingTile.bytes.lengthInBytes;
                        rootDeltaSize += diff;
                        return store..size += diff;
                      },
                    ).toList(growable: false),
                  );
                  updateRootStatistics(deltaSize: rootDeltaSize);
                case (true, true): // FMTC internal error
                  throw StateError(
                    'FMTC ObjectBox backend internal state error: $url',
                  );
              }
            },
          );

          sendRes(id: cmd.id);

          storeQuery.close();
          tilesQuery.close();
        case _WorkerCmdType.deleteTile:
          final storeName = cmd.args['storeName']! as String;
          final url = cmd.args['url']! as String;

          final query = root
              .box<ObjectBoxTile>()
              .query(ObjectBoxTile_.url.equals(url))
              .build();

          sendRes(
            id: cmd.id,
            data: {
              'wasOrphan':
                  deleteTiles(storeName: storeName, tilesQuery: query) == 1,
            },
          );

          query.close();
        case _WorkerCmdType.registerHitOrMiss:
          final storeName = cmd.args['storeName']! as String;
          final hit = cmd.args['hit']! as bool;

          final stores = root.box<ObjectBoxStore>();

          final query =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          root.runInTransaction(
            TxMode.write,
            () {
              final store = query.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              query.close();

              stores.put(
                store
                  ..hits += hit ? 1 : 0
                  ..misses += hit ? 0 : 1,
              );
            },
          );

          sendRes(id: cmd.id);
        case _WorkerCmdType.removeOldestTilesAboveLimit:
          final storeName = cmd.args['storeName']! as String;
          final tilesLimit = cmd.args['tilesLimit']! as int;

          final tilesQuery = (root
                  .box<ObjectBoxTile>()
                  .query()
                  .order(ObjectBoxTile_.lastModified)
                ..linkMany(
                  ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName),
                ))
              .build();

          final storeQuery = root
              .box<ObjectBoxStore>()
              .query(ObjectBoxStore_.name.equals(storeName))
              .build();

          final store = storeQuery.findUnique() ??
              (throw StoreNotExists(storeName: storeName));

          final numToRemove = store.length - tilesLimit;

          if (numToRemove <= 0) {
            sendRes(id: cmd.id, data: {'numOrphans': 0});
          } else {
            tilesQuery.limit = numToRemove;

            sendRes(
              id: cmd.id,
              data: {
                'numOrphans':
                    deleteTiles(storeName: storeName, tilesQuery: tilesQuery),
              },
            );
          }

          storeQuery.close();
          tilesQuery.close();
        case _WorkerCmdType.removeTilesOlderThan:
          final storeName = cmd.args['storeName']! as String;
          final expiry = cmd.args['expiry']! as DateTime;

          final tilesQuery = (root.box<ObjectBoxTile>().query(
                    ObjectBoxTile_.lastModified
                        .greaterThan(expiry.millisecondsSinceEpoch),
                  )..linkMany(
                  ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName),
                ))
              .build();

          sendRes(
            id: cmd.id,
            data: {
              'numOrphans':
                  deleteTiles(storeName: storeName, tilesQuery: tilesQuery),
            },
          );

          tilesQuery.close();
        case _WorkerCmdType.readMetadata:
          final storeName = cmd.args['storeName']! as String;

          final query = root
              .box<ObjectBoxStore>()
              .query(ObjectBoxStore_.name.equals(storeName))
              .build();

          final store = query.findUnique() ??
              (throw StoreNotExists(storeName: storeName));

          sendRes(
            id: cmd.id,
            data: {
              'metadata':
                  (jsonDecode(store.metadataJson) as Map<String, dynamic>)
                      .cast<String, String>(),
            },
          );

          query.close();
        case _WorkerCmdType.setMetadata:
          final storeName = cmd.args['storeName']! as String;
          final key = cmd.args['key']! as String;
          final value = cmd.args['value']! as String;

          final stores = root.box<ObjectBoxStore>();

          final query =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          root.runInTransaction(
            TxMode.write,
            () {
              final store = query.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              query.close();

              final Map<String, dynamic> json = store.metadataJson == ''
                  ? {}
                  : jsonDecode(store.metadataJson);
              json[key] = value;

              stores.put(
                store..metadataJson = jsonEncode(json),
                mode: PutMode.update,
              );
            },
          );

          sendRes(id: cmd.id);
        case _WorkerCmdType.setBulkMetadata:
          final storeName = cmd.args['storeName']! as String;
          final kvs = cmd.args['kvs']! as Map<String, String>;

          final stores = root.box<ObjectBoxStore>();

          final query =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          root.runInTransaction(
            TxMode.write,
            () {
              final store = query.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              query.close();

              final Map<String, dynamic> json = store.metadataJson == ''
                  ? {}
                  : jsonDecode(store.metadataJson);
              // ignore: cascade_invocations
              json.addAll(kvs);

              stores.put(
                store..metadataJson = jsonEncode(json),
                mode: PutMode.update,
              );
            },
          );

          sendRes(id: cmd.id);
        case _WorkerCmdType.removeMetadata:
          final storeName = cmd.args['storeName']! as String;
          final key = cmd.args['key']! as String;

          final stores = root.box<ObjectBoxStore>();

          final query =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          sendRes(
            id: cmd.id,
            data: {
              'removedValue': root.runInTransaction(
                TxMode.write,
                () {
                  final store = query.findUnique() ??
                      (throw StoreNotExists(storeName: storeName));
                  query.close();

                  final metadata =
                      jsonDecode(store.metadataJson) as Map<String, String>;
                  final removedVal = metadata.remove(key);

                  stores.put(
                    store..metadataJson = jsonEncode(metadata),
                    mode: PutMode.update,
                  );

                  return removedVal;
                },
              ),
            },
          );
        case _WorkerCmdType.resetMetadata:
          final storeName = cmd.args['storeName']! as String;

          final stores = root.box<ObjectBoxStore>();

          final query =
              stores.query(ObjectBoxStore_.name.equals(storeName)).build();

          root.runInTransaction(
            TxMode.write,
            () {
              final store = query.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              query.close();

              stores.put(
                store..metadataJson = jsonEncode(<String, String>{}),
                mode: PutMode.update,
              );
            },
          );

          sendRes(id: cmd.id);
        case _WorkerCmdType.listRecoverableRegions:
          sendRes(
            id: cmd.id,
            data: {
              'recoverableRegions': root
                  .box<ObjectBoxRecovery>()
                  .getAll()
                  .map((r) => r.toRegion())
                  .toList(growable: false),
            },
          );
        case _WorkerCmdType.getRecoverableRegion:
          final id = cmd.args['id']! as int;

          sendRes(
            id: cmd.id,
            data: {
              'recoverableRegion': (root
                      .box<ObjectBoxRecovery>()
                      .query(ObjectBoxRecovery_.refId.equals(id))
                      .build()
                    ..close())
                  .findUnique()
                  ?.toRegion(),
            },
          );
        case _WorkerCmdType.startRecovery:
          final id = cmd.args['id']! as int;
          final storeName = cmd.args['storeName']! as String;
          final region = cmd.args['region']! as DownloadableRegion;

          root.box<ObjectBoxRecovery>().put(
                ObjectBoxRecovery.fromRegion(
                  refId: id,
                  storeName: storeName,
                  region: region,
                ),
              );

          sendRes(id: cmd.id);
        case _WorkerCmdType.cancelRecovery:
          final id = cmd.args['id']! as int;

          root
              .box<ObjectBoxRecovery>()
              .query(ObjectBoxRecovery_.refId.equals(id))
              .build()
            ..remove()
            ..close();

          sendRes(id: cmd.id);
        case _WorkerCmdType.watchRecovery:
          final triggerImmediately = cmd.args['triggerImmediately']! as bool;

          streamedOutputSubscriptions[cmd.id] = root
              .box<ObjectBoxRecovery>()
              .query()
              .watch(triggerImmediately: triggerImmediately)
              .listen((_) => sendRes(id: cmd.id, data: {'expectStream': true}));
        case _WorkerCmdType.watchStores:
          final storeNames = cmd.args['storeNames']! as List<String>;
          final triggerImmediately = cmd.args['triggerImmediately']! as bool;

          streamedOutputSubscriptions[cmd.id] = root
              .box<ObjectBoxStore>()
              .query(
                storeNames.isEmpty
                    ? null
                    : ObjectBoxStore_.name.oneOf(storeNames),
              )
              .watch(triggerImmediately: triggerImmediately)
              .listen((_) => sendRes(id: cmd.id, data: {'expectStream': true}));
        case _WorkerCmdType.cancelWatch:
          final id = cmd.args['id']! as int;

          streamedOutputSubscriptions[id]?.cancel();
          streamedOutputSubscriptions.remove(id);

          sendRes(id: cmd.id);
      }
    } catch (e, s) {
      sendRes(id: cmd.id, data: {'error': e, 'stackTrace': s});
    }
  }).asFuture<void>();
}
