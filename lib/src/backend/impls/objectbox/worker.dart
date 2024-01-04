part of 'backend.dart';

enum _WorkerCmdType {
  initialise_, // Only valid as a response
  destroy_, // Only valid as a request
  storeExists,
  createStore,
  resetStore,
  renameStore,
  deleteStore,
  getStoreSize,
  getStoreLength,
  getStoreHits,
  getStoreMisses,
  tileExistsInStore,
  readTile,
  writeTile,
  deleteTile,
  removeOldestTilesAboveLimit,
  removeTilesOlderThan,
}

Future<void> _worker(
  ({
    SendPort sendPort,
    String? rootDirectory,
    int? maxDatabaseSize,
    String? macosApplicationGroup,
    int? maxReaders,
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
  final rootDirectory = await (input.rootDirectory == null
          ? await getApplicationDocumentsDirectory()
          : Directory(input.rootDirectory!) >> 'fmtc')
      .create(recursive: true);
  final root = await openStore(
    directory: rootDirectory.absolute.path,
    maxDBSizeInKB: input.maxDatabaseSize,
    macosApplicationGroup: input.macosApplicationGroup,
    maxReaders: input.maxReaders,
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
            ..numberOfTiles -= 1
            ..numberOfBytes -= tile.bytes.lengthInBytes,
          mode: PutMode.update,
        );
        break;
      }

      // Remove the store relation from the tile
      tile.stores.removeWhere((store) => store.name == storeName);

      // Delete the tile if it belongs to no stores
      if (tile.stores.isEmpty) return tiles.remove(tile.id);

      // Otherwise just update the tile
      tiles.put(tile, mode: PutMode.update);
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
            rootDirectory.deleteSync(recursive: true);
          }

          // TODO: Consider final message
          Isolate.exit();
        case _WorkerCmdType.storeExists:
          sendRes(
            id: cmd.id,
            data: {
              'exists': getStore(cmd.args['storeName']! as String) != null,
            },
          );

          break;
        case _WorkerCmdType.createStore:
          final storeName = cmd.args['storeName']! as String;

          try {
            root.box<ObjectBoxStore>().put(
                  ObjectBoxStore(
                    name: storeName,
                    numberOfTiles: 0,
                    numberOfBytes: 0,
                    hits: 0,
                    misses: 0,
                  ),
                  mode: PutMode.insert,
                );
          } catch (e) {
            throw StoreAlreadyExists(storeName: storeName);
          }

          sendRes(id: cmd.id);

          break;
        case _WorkerCmdType.resetStore:
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

              tiles.query(ObjectBoxTile_.id.oneOf(removeIds)).build()
                ..remove()
                ..close();

              final store = storeQuery.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              storeQuery.close();

              assert(store.tiles.isEmpty);
              // TODO: Hits & misses

              stores.put(
                store
                  ..tiles.clear()
                  ..numberOfTiles = 0
                  ..numberOfBytes = 0
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

          root.box<ObjectBoxStore>().put(
                getStore(currentStoreName) ??
                    (throw StoreNotExists(storeName: currentStoreName))
                  ..name = newStoreName,
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

          sendRes(id: cmd.id);

          break;
        case _WorkerCmdType.getStoreSize:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            id: cmd.id,
            data: {
              'size': (getStore(storeName) ??
                          (throw StoreNotExists(storeName: storeName)))
                      .numberOfBytes /
                  1024,
            },
          );

          break;
        case _WorkerCmdType.getStoreLength:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            id: cmd.id,
            data: {
              'length': (getStore(storeName) ??
                      (throw StoreNotExists(storeName: storeName)))
                  .numberOfTiles,
            },
          );

          break;
        case _WorkerCmdType.getStoreHits:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            id: cmd.id,
            data: {
              'hits': (getStore(storeName) ??
                      (throw StoreNotExists(storeName: storeName)))
                  .hits,
            },
          );

          break;
        case _WorkerCmdType.getStoreMisses:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            id: cmd.id,
            data: {
              'misses': (getStore(storeName) ??
                      (throw StoreNotExists(storeName: storeName)))
                  .misses,
            },
          );

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
                      ..numberOfTiles += 1
                      ..numberOfBytes += bytes.lengthInBytes,
                  );
                  break;
                case (false, true): // Existing tile, no update
                  // Only take action if it's not already belonging to the store
                  if (!existingTile!.stores.contains(store)) {
                    tiles.put(existingTile..stores.add(store));
                    stores.put(
                      store
                        ..numberOfTiles += 1
                        ..numberOfBytes += existingTile.bytes.lengthInBytes,
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
                            ..numberOfBytes += (bytes.lengthInBytes -
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

                      final numToRemove = store.numberOfTiles - tilesLimit;

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
      }
    } catch (e) {
      sendRes(id: cmd.id, data: {'error': e});
    }
  }
}
