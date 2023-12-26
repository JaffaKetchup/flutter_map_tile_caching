part of 'backend.dart';

typedef _WorkerCmd = ({_WorkerKey key, Map<String, Object?> args});
typedef _WorkerRes = ({_WorkerKey key, Map<String, Object?>? data});

enum _WorkerKey {
  initialise_, // Only valid as a response
  destroy_, // Only valid as a request
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
  void sendRes(_WorkerRes m) => input.sendPort.send(m);

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
      key: _WorkerKey.initialise_,
      data: {'sendPort': receivePort.sendPort},
    ),
  );

  // Await cmds, perform work, and respond
  await for (final _WorkerCmd cmd in receivePort) {
    switch (cmd.key) {
      case _WorkerKey.initialise_:
        throw UnsupportedError('Invalid operation');
      case _WorkerKey.destroy_:
        root.close();
        if (cmd.args['deleteRoot'] == true) {
          rootDirectory.deleteSync(recursive: true);
        }
        Isolate.exit();
      case _WorkerKey.createStore:
        root.box<ObjectBoxStore>().put(
              ObjectBoxStore(
                name: cmd.args['storeName']! as String,
                numberOfTiles: 0,
                numberOfBytes: 0,
                hits: 0,
                misses: 0,
              ),
              mode: PutMode.insert,
            );
        sendRes((key: cmd.key, data: null));
        break;
      case _WorkerKey.resetStore:
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
                    tile.stores.removeWhere((store) => store.name == storeName);
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
                (throw StoreUnavailable(storeName: storeName));
            storeQuery.close();

            assert(store.tiles.isEmpty);

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
        sendRes((key: cmd.key, data: null));
        break;
      case _WorkerKey.renameStore:
        final currentStoreName = cmd.args['currentStoreName']! as String;
        final newStoreName = cmd.args['newStoreName']! as String;

        root.box<ObjectBoxStore>().put(
              root
                      .box<ObjectBoxStore>()
                      .query(ObjectBoxStore_.name.equals(currentStoreName))
                      .build()
                      .findUnique() ??
                  (throw StoreUnavailable(storeName: currentStoreName))
                ..name = newStoreName,
            );

        sendRes((key: cmd.key, data: null));
        break;
      case _WorkerKey.deleteStore:
        root
            .box<ObjectBoxStore>()
            .query(
              ObjectBoxStore_.name.equals(cmd.args['storeName']! as String),
            )
            .build()
          ..remove()
          ..close();

        sendRes((key: cmd.key, data: null));
        break;
      case _WorkerKey.getStoreSize:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final kib = (query.findUnique() ??
                    (throw StoreUnavailable(storeName: storeName)))
                .numberOfBytes /
            1024;
        query.close();

        sendRes((key: cmd.key, data: {'size': kib}));
        break;
      case _WorkerKey.getStoreLength:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final length = (query.findUnique() ??
                (throw StoreUnavailable(storeName: storeName)))
            .numberOfTiles;
        query.close();

        sendRes((key: cmd.key, data: {'length': length}));
        break;
      case _WorkerKey.getStoreHits:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final hits = (query.findUnique() ??
                (throw StoreUnavailable(storeName: storeName)))
            .hits;
        query.close();

        sendRes((key: cmd.key, data: {'hits': hits}));
        break;
      case _WorkerKey.getStoreMisses:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final misses = (query.findUnique() ??
                (throw StoreUnavailable(storeName: storeName)))
            .misses;
        query.close();

        sendRes((key: cmd.key, data: {'misses': misses}));
        break;
      case _WorkerKey.readTile:
        final query = root
            .box<ObjectBoxTile>()
            .query(ObjectBoxTile_.url.equals(cmd.args['url']! as String))
            .build();
        final tile = query.findUnique();
        query.close();

        // TODO: Hits & misses

        sendRes((key: cmd.key, data: {'tile': tile}));
        break;
      case _WorkerKey.writeTile:
        final storeName = cmd.args['storeName']! as String;
        final url = cmd.args['url']! as String;
        final bytes = cmd.args['bytes'] as Uint8List?;

        final tiles = root.box<ObjectBoxTile>();
        final stores = root.box<ObjectBoxStore>();

        final tilesQuery = tiles.query(ObjectBoxTile_.url.equals(url)).build();
        final existingTile = tilesQuery.findUnique();
        tilesQuery.close();

        final storeQuery =
            stores.query(ObjectBoxStore_.name.equals(storeName)).build();
        final store = storeQuery.findUnique() ??
            (throw StoreUnavailable(storeName: storeName));
        storeQuery.close();

        root.runInTransaction(
          TxMode.write,
          () {
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

        sendRes((key: cmd.key, data: null));
        break;
      case _WorkerKey.deleteTile:
        final storeName = cmd.args['storeName']! as String;
        final url = cmd.args['url']! as String;

        final tiles = root.box<ObjectBoxTile>();

        // Find the tile by URL
        final query = tiles.query(ObjectBoxTile_.url.equals(url)).build();
        final tile = query.findUnique();
        if (tile == null) {
          sendRes((key: cmd.key, data: {'wasOrphaned': null}));
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
          sendRes((key: cmd.key, data: {'wasOrphaned': true}));
          break;
        }

        // Otherwise just update the tile
        query.close();
        tiles.put(tile, mode: PutMode.update);
        sendRes((key: cmd.key, data: {'wasOrphaned': false}));
        break;
      case _WorkerKey.removeOldestTile:
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
          sendRes((key: cmd.key, data: null));
          break;
        }

        final storeQuery = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final store = storeQuery.findUnique() ??
            (throw StoreUnavailable(storeName: storeName));
        storeQuery.close();

        root.runInTransaction(
          TxMode.write,
          () {
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

        sendRes((key: cmd.key, data: null));
        break;
    }
  }
}
