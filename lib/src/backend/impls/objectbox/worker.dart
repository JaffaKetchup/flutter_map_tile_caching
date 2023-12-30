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
  readTile,
  writeTile,
  deleteTile,
  removeOldestTile,
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
  // Setup comms
  final receivePort = ReceivePort();
  void sendRes(({int id, Map<String, dynamic>? data}) m) =>
      input.sendPort.send(m);

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
    (
      id: 0,
      data: {'sendPort': receivePort.sendPort},
    ),
  );

  // Setup util functions
  ObjectBoxStore? getStore(String storeName) {
    final query = root
        .box<ObjectBoxStore>()
        .query(ObjectBoxStore_.name.equals(storeName))
        .build();
    final store = query.findUnique();
    query.close();
    return store;
  }

  // Await cmds, perform work, and respond
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
            (
              id: cmd.id,
              data: {
                'exists': getStore(cmd.args['storeName']! as String) != null,
              },
            ),
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
          sendRes((id: cmd.id, data: null));
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
          sendRes((id: cmd.id, data: null));
          break;
        case _WorkerCmdType.renameStore:
          final currentStoreName = cmd.args['currentStoreName']! as String;
          final newStoreName = cmd.args['newStoreName']! as String;

          root.box<ObjectBoxStore>().put(
                getStore(currentStoreName) ??
                    (throw StoreNotExists(storeName: currentStoreName))
                  ..name = newStoreName,
              );

          sendRes((id: cmd.id, data: null));
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

          sendRes((id: cmd.id, data: null));
          break;
        case _WorkerCmdType.getStoreSize:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            (
              id: cmd.id,
              data: {
                'size': (getStore(storeName) ??
                            (throw StoreNotExists(storeName: storeName)))
                        .numberOfBytes /
                    1024,
              }
            ),
          );
          break;
        case _WorkerCmdType.getStoreLength:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            (
              id: cmd.id,
              data: {
                'length': (getStore(storeName) ??
                        (throw StoreNotExists(storeName: storeName)))
                    .numberOfTiles,
              }
            ),
          );
          break;
        case _WorkerCmdType.getStoreHits:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            (
              id: cmd.id,
              data: {
                'hits': (getStore(storeName) ??
                        (throw StoreNotExists(storeName: storeName)))
                    .hits,
              }
            ),
          );
          break;
        case _WorkerCmdType.getStoreMisses:
          final storeName = cmd.args['storeName']! as String;

          sendRes(
            (
              id: cmd.id,
              data: {
                'misses': (getStore(storeName) ??
                        (throw StoreNotExists(storeName: storeName)))
                    .misses,
              }
            ),
          );
          break;
        case _WorkerCmdType.readTile:
          final query = root
              .box<ObjectBoxTile>()
              .query(ObjectBoxTile_.url.equals(cmd.args['url']! as String))
              .build();
          final tile = query.findUnique();
          query.close();

          // TODO: Hits & misses

          sendRes((id: cmd.id, data: {'tile': tile}));
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
                      lastModified: DateTime.now(),
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
                      ..lastModified = DateTime.now()
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
                  throw TileCannotUpdate(url: url);
              }
            },
          );

          sendRes((id: cmd.id, data: null));
          break;
        case _WorkerCmdType.deleteTile:
          final storeName = cmd.args['storeName']! as String;
          final url = cmd.args['url']! as String;

          final tiles = root.box<ObjectBoxTile>();

          // Find the tile by URL
          final query = tiles.query(ObjectBoxTile_.url.equals(url)).build();
          final tile = query.findUnique();
          if (tile == null) {
            sendRes((id: cmd.id, data: {'wasOrphaned': null}));
            break;
          }

          // For the correct store, adjust the statistics
          for (final store in tile.stores) {
            if (store.name != storeName) continue;
            root.box<ObjectBoxStore>().put(
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
          if (tile.stores.isEmpty) {
            query
              ..remove()
              ..close();
            sendRes((id: cmd.id, data: {'wasOrphaned': true}));
            break;
          }

          // Otherwise just update the tile
          query.close();
          tiles.put(tile, mode: PutMode.update);
          sendRes((id: cmd.id, data: {'wasOrphaned': false}));
          break;
        case _WorkerCmdType.removeOldestTile:
          final storeName = cmd.args['storeName']! as String;
          final numTilesToRemove = cmd.args['number']! as int;

          final tiles = root.box<ObjectBoxTile>();

          final tilesQuery = (tiles.query().order(ObjectBoxTile_.lastModified)
                ..linkMany(
                  ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName),
                ))
              .build();
          final deleteTiles = await tilesQuery
              .stream()
              .where((tile) => tile.stores.length == 1)
              .take(numTilesToRemove)
              .toList();
          tilesQuery.close();

          if (deleteTiles.isEmpty) {
            sendRes((id: cmd.id, data: null));
            break;
          }

          final storeQuery = root
              .box<ObjectBoxStore>()
              .query(ObjectBoxStore_.name.equals(storeName))
              .build();

          root.runInTransaction(
            TxMode.write,
            () {
              final store = storeQuery.findUnique() ??
                  (throw StoreNotExists(storeName: storeName));
              storeQuery.close();

              root.box<ObjectBoxStore>().put(
                    store
                      ..numberOfTiles -= numTilesToRemove
                      ..numberOfBytes -=
                          deleteTiles.map((e) => e.bytes.lengthInBytes).sum,
                    mode: PutMode.update,
                  );
              tiles.removeMany(deleteTiles.map((e) => e.id).toList());
            },
          );

          sendRes((id: cmd.id, data: null));
          break;
      }
    } catch (e) {
      sendRes((id: cmd.id, data: {'error': e}));
    }
  }
}
