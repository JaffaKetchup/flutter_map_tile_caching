// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

enum _WorkerCmdType {
  initialise_, // Only valid as a response
  destroy_, // Only valid as a request
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
  removeOldestTilesAboveLimit,
  removeTilesOlderThan,
  readMetadata,
  setMetadata,
  setBulkMetadata,
  removeMetadata,
  resetMetadata,
}

Future<void> _worker(
  ({
    SendPort sendPort,
    Directory rootDirectory,
    int? maxDatabaseSize,
    String? macosApplicationGroup,
  }) input,
) async {
  //! SETUP !//

  // Setup comms
  final receivePort = ReceivePort();
  void sendRes({
    required int id,
    Map<String, dynamic>? data,
  }) =>
      input.sendPort.send((id: id, data: data));

  // Initialise database
  final root = await openStore(
    directory: input.rootDirectory.absolute.path,
    maxDBSizeInKB: input.maxDatabaseSize ?? 10000000, // Defaults to 10 GB
    macosApplicationGroup: input.macosApplicationGroup,
  );

  // Respond with comms channel for future cmds
  sendRes(
    id: 0,
    data: {'sendPort': receivePort.sendPort},
  );

  //! UTIL FUNCTIONS !//

  /// Convert store name to database store object
  ///
  /// Returns `null` if store not found. Throw the [StoreNotExists] error if it
  /// was required.
  ObjectBoxStore? getStore(String storeName) {
    final query = root
        .box<ObjectBoxStore>()
        .query(ObjectBoxStore_.name.equals(storeName))
        .build();
    final store = query.findUnique();
    query.close();
    return store;
  }

  /// Delete the specified tiles from the specified store
  ///
  /// Note that [tilesQuery] is not closed internally. Ensure it is closed after
  /// usage.
  ///
  /// Returns whether each tile was actually deleted (whether it was an orphan),
  /// in iteration order of [tilesQuery.find].
  Iterable<bool> deleteTiles({
    required String storeName,
    required Query<ObjectBoxTile> tilesQuery,
  }) {
    final stores = root.box<ObjectBoxStore>();
    final tiles = root.box<ObjectBoxTile>();

    return tilesQuery.find().map((tile) {
      // For the correct store, adjust the statistics
      for (final store in tile.stores) {
        if (store.name != storeName) continue;
        stores.put(
          store
            ..length -= 1
            ..size -= tile.bytes.lengthInBytes,
          mode: PutMode.update,
        );
        break;
      }

      // Remove the store relation from the tile
      tile.stores.removeWhere((store) => store.name == storeName);

      // Delete the tile if it belongs to no stores
      if (tile.stores.isEmpty) return tiles.remove(tile.id);

      // Otherwise just update the tile
      // TODO: Check this works
      tile.stores.applyToDb(mode: PutMode.update);
      return false;
    });
  }

  //! MAIN LOOP !//

  await for (final ({
    int id,
    _WorkerCmdType type,
    Map<String, dynamic> args,
  }) cmd in receivePort) {
    try {
      switch (cmd.type) {
        case _WorkerCmdType.initialise_:
          throw UnsupportedError('Invalid operation');
        case _WorkerCmdType.destroy_:
          root.close();
          if (cmd.args['deleteRoot'] == true) {
            input.rootDirectory.deleteSync(recursive: true);
          }

          // TODO: Consider final message
          Isolate.exit();
        case _WorkerCmdType.storeExists:
          final query = root
              .box<ObjectBoxStore>()
              .query(
                ObjectBoxStore_.name.equals(cmd.args['storeName']! as String),
              )
              .build();

          sendRes(id: cmd.id, data: {'exists': query.count() == 1});

          query.close();

          break;
        case _WorkerCmdType.getStoreStats:
          final storeName = cmd.args['storeName']! as String;
          final store = getStore(storeName) ??
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

          break;
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
                  ),
                  mode: PutMode.insert,
                );
          } catch (e) {
            debugPrint(e.runtimeType.toString());
            throw StoreAlreadyExists(storeName: storeName);
          }

          sendRes(id: cmd.id);

          break;
        case _WorkerCmdType.resetStore:
          // TODO: Consider just deleting then creating
          final storeName = cmd.args['storeName']! as String;
          final removeIds = <int>[];

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
              tiles.putMany(
                tilesQuery
                    .find()
                    .map((tile) {
                      tile.stores
                          .removeWhere((store) => store.name == storeName);
                      if (tile.stores.isNotEmpty) return tile;
                      removeIds.add(tile.id);
                      return null;
                    })
                    .whereNotNull()
                    .toList(),
                mode: PutMode.update,
              );
              tilesQuery.close();

              tiles.removeMany(removeIds);

              final store = storeQuery.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              storeQuery.close();

              assert(store.tiles.isEmpty);
              // TODO: Hits & misses

              stores.put(
                store
                  ..tiles.clear()
                  ..length = 0
                  ..size = 0
                  ..hits = 0
                  ..misses = 0,
              );
            },
          );

          sendRes(id: cmd.id);

          break;
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

          break;
        case _WorkerCmdType.deleteStore:
          root
              .box<ObjectBoxStore>()
              .query(
                ObjectBoxStore_.name.equals(cmd.args['storeName']! as String),
              )
              .build()
            ..remove()
            ..close();

          // TODO: Check tiles relations
          // TODO: Integrate metadata

          sendRes(id: cmd.id);

          break;
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

          break;
        case _WorkerCmdType.readTile:
          final url = cmd.args['url']! as String;

          final query = root
              .box<ObjectBoxTile>()
              .query(ObjectBoxTile_.url.equals(url))
              .build();

          sendRes(id: cmd.id, data: {'tile': query.findUnique()});

          query.close();

          break;
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

          break;
        case _WorkerCmdType.writeTile:
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
              tilesQuery.close();

              final store = storeQuery.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              storeQuery.close();

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
                  break;
                case (false, true): // Existing tile, no update
                  // Only take action if it's not already belonging to the store
                  if (!existingTile!.stores.contains(store)) {
                    tiles.put(existingTile..stores.add(store));
                    stores.put(
                      store
                        ..length += 1
                        ..size += existingTile.bytes.lengthInBytes,
                    );
                  }
                  break;
                case (false, false): // Existing tile, update required
                  tiles.put(
                    existingTile!
                      ..lastModified = DateTime.timestamp()
                      ..bytes = bytes!,
                  );
                  stores.putMany(
                    existingTile.stores
                        .map(
                          (store) => store
                            ..size += (bytes.lengthInBytes -
                                existingTile.bytes.lengthInBytes),
                        )
                        .toList(),
                  );
                  break;
                case (true, true): // FMTC internal error
                  throw StateError(
                    'FMTC ObjectBox backend internal state error: $url',
                  );
              }
            },
          );

          sendRes(id: cmd.id);

          break;
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
              'wasOrphan': root
                  .runInTransaction(
                    TxMode.write,
                    () => deleteTiles(storeName: storeName, tilesQuery: query),
                  )
                  .singleOrNull,
            },
          );

          query.close();

          break;
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

          sendRes(
            id: cmd.id,
            data: {
              'numOrphans': root
                  .runInTransaction(
                    TxMode.write,
                    () {
                      final store = storeQuery.findUnique() ??
                          (throw StoreNotExists(storeName: storeName));

                      final numToRemove = store.length - tilesLimit;

                      return numToRemove <= 0
                          ? const Iterable.empty()
                          : deleteTiles(
                              storeName: storeName,
                              tilesQuery: tilesQuery..limit = numToRemove,
                            );
                    },
                  )
                  .where((e) => e)
                  .length,
            },
          );

          storeQuery.close();
          tilesQuery.close();

          break;
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
              'numOrphans': root
                  .runInTransaction(
                    TxMode.write,
                    () => deleteTiles(
                      storeName: storeName,
                      tilesQuery: tilesQuery,
                    ),
                  )
                  .where((e) => e)
                  .length,
            },
          );

          tilesQuery.close();

          break;
        case _WorkerCmdType.readMetadata:
          final storeName = cmd.args['storeName']! as String;
          final store = getStore(storeName) ??
              (throw StoreNotExists(storeName: storeName));

          sendRes(
            id: cmd.id,
            data: {'metadata': jsonDecode(store.metadataJson)},
          );

          break;
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

              stores.put(
                store
                  ..metadataJson = jsonEncode(
                    (jsonDecode(store.metadataJson)
                        as Map<String, String>)[key] = value,
                  ),
                mode: PutMode.update,
              );
            },
          );

          sendRes(id: cmd.id);

          break;
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

              stores.put(
                store
                  ..metadataJson = jsonEncode(
                    (jsonDecode(store.metadataJson) as Map<String, String>)
                      ..addAll(kvs),
                  ),
                mode: PutMode.update,
              );
            },
          );

          sendRes(id: cmd.id);

          break;
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

          break;
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

          break;
      }
    } catch (e) {
      sendRes(id: cmd.id, data: {'error': e});
    }
  }
}
