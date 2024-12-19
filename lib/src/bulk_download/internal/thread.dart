// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

Future<void> _singleDownloadThread(
  ({
    SendPort sendPort,
    String storeName,
    TileLayer options,
    int maxBufferLength,
    bool skipExistingTiles,
    Uint8List? seaTileBytes,
    String Function(String) urlTransformer,
    Map<String, String> headers,
    FMTCBackendInternalThreadSafe backend,
  }) input,
) async {
  // Setup two-way communications
  final receivePort = ReceivePort();
  void send(Object m) => input.sendPort.send(m);
  send(receivePort.sendPort);

  // Setup tile queue
  final tileQueue = StreamQueue(receivePort);

  // Initialise a long lasting HTTP client
  final httpClient = IOClient();

  // Initialise the tile buffer arrays
  final tileUrlsBuffer = <String>[];
  final tileBytesBuffer = <Uint8List>[];

  await input.backend.initialise();

  while (true) {
    // Request new data from manager
    send(0);
    final managerInput = (await tileQueue.next) as ({
      (int, int, int) tileCoordinates,
      bool isRetryAttempt,
    })?;

    // Cleanup resources and shutdown if no more data available
    if (managerInput == null) {
      receivePort.close();
      await tileQueue.cancel(immediate: true);

      httpClient.close();

      if (tileUrlsBuffer.isNotEmpty) {
        await input.backend.writeTiles(
          storeName: input.storeName,
          urls: tileUrlsBuffer,
          bytess: tileBytesBuffer,
        );
      }

      await input.backend.uninitialise();

      Isolate.exit();
    }

    // Destructure data from manager
    final (:tileCoordinates, :isRetryAttempt) = managerInput;

    // Get new tile URLs
    final networkUrl = input.options.tileProvider.getTileUrl(
      TileCoordinates(
        tileCoordinates.$1,
        tileCoordinates.$2,
        tileCoordinates.$3,
      ),
      input.options,
    );
    final matcherUrl = input.urlTransformer(networkUrl);

    // If skipping existing tile, perform extra checks
    if (input.skipExistingTiles) {
      if ((await input.backend.readTile(
        url: matcherUrl,
        storeName: input.storeName,
      ))
              ?.bytes
          case final bytes?) {
        send(
          ExistingTileEvent._(
            url: networkUrl,
            coordinates: tileCoordinates,
            tileImage: Uint8List.fromList(bytes),
            // Never a retry attempt
          ),
        );
        continue;
      }
    }

    // Fetch new tile from URL
    final Response response;
    try {
      response =
          await httpClient.get(Uri.parse(networkUrl), headers: input.headers);
    } catch (err) {
      send(
        FailedRequestTileEvent._(
          url: networkUrl,
          coordinates: tileCoordinates,
          fetchError: err,
          wasRetryAttempt: isRetryAttempt,
        ),
      );
      continue;
    }

    if (response.statusCode != 200) {
      send(
        NegativeResponseTileEvent._(
          url: networkUrl,
          coordinates: tileCoordinates,
          fetchResponse: response,
          wasRetryAttempt: isRetryAttempt,
        ),
      );
      continue;
    }

    // Skip if tile is a sea tile & user demands sea tile pruning
    if (const ListEquality().equals(response.bodyBytes, input.seaTileBytes)) {
      send(
        SeaTileEvent._(
          url: networkUrl,
          coordinates: tileCoordinates,
          tileImage: response.bodyBytes,
          fetchResponse: response,
          wasRetryAttempt: isRetryAttempt,
        ),
      );
      continue;
    }

    // Write tile directly to database or place in buffer queue
    if (input.maxBufferLength == 0) {
      await input.backend.writeTile(
        storeName: input.storeName,
        url: matcherUrl,
        bytes: response.bodyBytes,
      );
    } else {
      tileUrlsBuffer.add(matcherUrl);
      tileBytesBuffer.add(response.bodyBytes);
    }

    // Write buffer to database if necessary
    // Must set flag appropriately to indicate to manager whether the buffer
    // stats and counters should be reset
    final wasBufferFlushed = tileUrlsBuffer.length >= input.maxBufferLength;
    if (wasBufferFlushed) {
      await input.backend.writeTiles(
        storeName: input.storeName,
        urls: tileUrlsBuffer,
        bytess: tileBytesBuffer,
      );
      tileUrlsBuffer.clear();
      tileBytesBuffer.clear();
    }

    // Return successful response to user
    send(
      SuccessfulTileEvent._(
        url: networkUrl,
        coordinates: tileCoordinates,
        tileImage: response.bodyBytes,
        fetchResponse: response,
        wasBufferFlushed: wasBufferFlushed,
        wasRetryAttempt: isRetryAttempt,
      ),
    );
  }
}
