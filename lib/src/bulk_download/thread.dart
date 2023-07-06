// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

Future<void> _singleDownloadThread(
  ({
    SendPort sendPort,
    String storeId,
    String rootDirectory,
    DownloadableRegion region,
    FMTCTileProvider tileProvider,
    int maxBufferLength,
    bool skipExistingTiles,
    Uint8List? seaTileBytes,
  }) input,
) async {
  // Setup two-way communications
  final recievePort = ReceivePort();
  void send(Object m) => input.sendPort.send(m);
  send(recievePort.sendPort);

  // Setup tile queue
  final tileQueue = StreamQueue(recievePort);

  // Open a reference to the Isar DB for the current store
  final db = Isar.openSync(
    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
    name: input.storeId,
    directory: input.rootDirectory,
    inspector: false,
  );

  // Initialise a long lasting HTTP client
  final httpClient = http.Client();

  // Initialise the tile buffer array
  final tileBuffer = <DbTile>[];

  while (true) {
    // Request new tile coords
    send(0);
    final coords = (await tileQueue.next) as (int, int, int)?;

    // Cleanup resources and shutdown if no more coords available
    if (coords == null) {
      recievePort.close();
      await tileQueue.cancel(immediate: true);

      httpClient.close();

      if (tileBuffer.isNotEmpty) {
        db.writeTxnSync(() => db.tiles.putAllSync(tileBuffer));
      }
      await db.close();

      Isolate.exit();
    }

    // Get new tile URL & any existing tile
    final url = input.tileProvider.getTileUrl(
      TileCoordinates(coords.$1, coords.$2, coords.$3),
      input.region.options,
    );
    final existingTile = await db.tiles.get(DatabaseTools.hash(url));

    // Skip if tile already exists and user demands existing tile pruning
    if (input.skipExistingTiles && existingTile != null) {
      send(
        TileEvent._(
          TileEventResult.alreadyExisting,
          url: url,
          tileImage: Uint8List.fromList(existingTile.bytes),
        ),
      );
      continue;
    }

    // Fetch new tile from URL
    final http.Response response;
    try {
      response = await httpClient.get(
        Uri.parse(url),
        headers: input.tileProvider.headers,
      );
    } catch (e) {
      send(
        TileEvent._(
          e is SocketException
              ? TileEventResult.noConnectionDuringFetch
              : TileEventResult.unknownFetchException,
          url: url,
          fetchError: e,
        ),
      );
      continue;
    }

    if (response.statusCode != 200) {
      send(
        TileEvent._(
          TileEventResult.negativeFetchResponse,
          url: url,
          fetchResponse: response,
        ),
      );
      continue;
    }

    // Skip if tile is a sea tile & user demands sea tile pruning
    if (const ListEquality().equals(response.bodyBytes, input.seaTileBytes)) {
      send(
        TileEvent._(
          TileEventResult.isSeaTile,
          url: url,
          tileImage: response.bodyBytes,
          fetchResponse: response,
        ),
      );
      continue;
    }

    // Write tile directly to database or place in buffer queue
    final tile = DbTile(url: url, bytes: response.bodyBytes);
    if (input.maxBufferLength == 0) {
      db.writeTxnSync(() => db.tiles.putSync(tile));
    } else {
      tileBuffer.add(tile);
    }

    // Write buffer to database if necessary
    final wasBufferReset = tileBuffer.length >= input.maxBufferLength;
    if (wasBufferReset) {
      db.writeTxnSync(() => db.tiles.putAllSync(tileBuffer));
      tileBuffer.clear();
    }

    // Return successful response to user
    send(
      TileEvent._(
        TileEventResult.success,
        url: url,
        tileImage: response.bodyBytes,
        fetchResponse: response,
        wasBufferReset: wasBufferReset,
      ),
    );
  }
}
