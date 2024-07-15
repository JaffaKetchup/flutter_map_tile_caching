// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

Future<Uint8List> _internalGetBytes({
  required TileCoordinates coords,
  required TileLayer options,
  required FMTCTileProvider provider,
  required StreamController<ImageChunkEvent>? chunkEvents,
  required bool requireValidImage,
  required TileLoadingDebugInfo? currentTLDI,
}) async {
  void registerHit(List<String> storeNames) {
    currentTLDI?.hitOrMiss = true;
    if (provider.settings.recordHitsAndMisses) {
      FMTCBackendAccess.internal
          .registerHitOrMiss(storeNames: storeNames, hit: true);
    }
  }

  void registerMiss() {
    currentTLDI?.hitOrMiss = false;
    if (provider.settings.recordHitsAndMisses) {
      FMTCBackendAccess.internal.registerHitOrMiss(
        storeNames: provider._getSpecifiedStoresOrNull(), // TODO: Verify
        hit: false,
      );
    }
  }

  final networkUrl = provider.getTileUrl(coords, options);
  final matcherUrl = provider.settings.urlTransformer(networkUrl);

  currentTLDI?.networkUrl = networkUrl;
  currentTLDI?.storageSuitableUID = matcherUrl;

  final (
    tile: existingTile,
    intersectedStoreNames: intersectedExistingStores,
    allStoreNames: allExistingStores,
  ) = await FMTCBackendAccess.internal.readTile(
    url: matcherUrl,
    storeNames: provider._getSpecifiedStoresOrNull(),
  );

  currentTLDI?.existingStores =
      allExistingStores.isEmpty ? null : allExistingStores;

  final tileExistsInUnspecifiedStoresOnly = existingTile != null &&
      provider.settings.useOtherStoresAsFallbackOnly &&
      provider.storeNames.keys
          .toSet()
          .union(
            allExistingStores.toSet(),
          ) // TODO: Verify (intersect? simplify?)
          .isEmpty;

  currentTLDI?.tileExistsInUnspecifiedStoresOnly =
      tileExistsInUnspecifiedStoresOnly;

  // Prepare a list of image bytes and prefill if there's already a cached
  // tile available
  Uint8List? bytes;
  if (existingTile != null) bytes = existingTile.bytes;

  // If there is a cached tile that's in date available, use it
  final needsUpdating = existingTile != null &&
      (provider.settings.behavior == CacheBehavior.onlineFirst ||
          (provider.settings.cachedValidDuration != Duration.zero &&
              DateTime.timestamp().millisecondsSinceEpoch -
                      existingTile.lastModified.millisecondsSinceEpoch >
                  provider.settings.cachedValidDuration.inMilliseconds));

  currentTLDI?.needsUpdating = needsUpdating;

  if (existingTile != null &&
      !needsUpdating &&
      !tileExistsInUnspecifiedStoresOnly) {
    currentTLDI?.result = TileLoadingDebugResultPath.perfectFromStores;
    currentTLDI?.writeResult = null;

    registerHit(intersectedExistingStores);
    return bytes!;
  }

  // If a tile is not available and cache only mode is in use, just fail
  // before attempting a network call
  if (provider.settings.behavior == CacheBehavior.cacheOnly) {
    if (existingTile != null) {
      currentTLDI?.result = TileLoadingDebugResultPath.cacheOnlyFromOtherStores;
      currentTLDI?.writeResult = null;

      registerMiss();
      return bytes!;
    }

    throw FMTCBrowsingError(
      type: FMTCBrowsingErrorType.missingInCacheOnlyMode,
      networkUrl: networkUrl,
      storageSuitableUID: matcherUrl,
    );

    /*if (tileExistsInUnspecifiedStoresOnly) {
      registerMiss();
      return bytes!;
    }
    if (existingTile == null) {
      throw FMTCBrowsingError(
        type: FMTCBrowsingErrorType.missingInCacheOnlyMode,
        networkUrl: networkUrl,
        matcherUrl: matcherUrl,
      );
    }*/
  }

  // Setup a network request for the tile & handle network exceptions
  final request = http.Request('GET', Uri.parse(networkUrl))
    ..headers.addAll(provider.headers);
  final http.StreamedResponse response;
  try {
    response = await provider.httpClient.send(request);
  } catch (e) {
    if (existingTile != null) {
      currentTLDI?.result = TileLoadingDebugResultPath.noFetch;
      currentTLDI?.writeResult = null;

      registerMiss();
      return bytes!;
    }

    throw FMTCBrowsingError(
      type: e is SocketException
          ? FMTCBrowsingErrorType.noConnectionDuringFetch
          : FMTCBrowsingErrorType.unknownFetchException,
      networkUrl: networkUrl,
      storageSuitableUID: matcherUrl,
      request: request,
      originalError: e,
    );
  }

  // Check whether the network response is not 200 OK
  if (response.statusCode != 200) {
    if (existingTile != null) {
      currentTLDI?.result = TileLoadingDebugResultPath.noFetch;
      currentTLDI?.writeResult = null;

      registerMiss();
      return bytes!;
    }

    throw FMTCBrowsingError(
      type: FMTCBrowsingErrorType.negativeFetchResponse,
      networkUrl: networkUrl,
      storageSuitableUID: matcherUrl,
      request: request,
      response: response,
    );
  }

  // Extract the image bytes from the streamed network response
  final bytesBuilder = BytesBuilder(copy: false);
  await for (final byte in response.stream) {
    bytesBuilder.add(byte);
    chunkEvents?.add(
      ImageChunkEvent(
        cumulativeBytesLoaded: bytesBuilder.length,
        expectedTotalBytes: response.contentLength,
      ),
    );
  }
  final responseBytes = bytesBuilder.takeBytes();

  // Perform a secondary check to ensure that the bytes recieved actually
  // encode a valid image
  if (requireValidImage) {
    late final Object? isValidImageData;

    try {
      isValidImageData = (await (await instantiateImageCodec(
                responseBytes,
                targetWidth: 8,
                targetHeight: 8,
              ))
                      .getNextFrame())
                  .image
                  .width >
              0
          ? null
          : Exception('Image was decodable, but had a width of 0');
    } catch (e) {
      isValidImageData = e;
    }

    if (isValidImageData != null) {
      if (existingTile != null) {
        currentTLDI?.result = TileLoadingDebugResultPath.noFetch;
        currentTLDI?.writeResult = null;

        registerMiss();
        return bytes!;
      }

      throw FMTCBrowsingError(
        type: FMTCBrowsingErrorType.invalidImageData,
        networkUrl: networkUrl,
        storageSuitableUID: matcherUrl,
        request: request,
        response: response,
        originalError: isValidImageData,
      );
    }
  }

  // Find the stores that need to have this tile written to, depending on
  // their read/write settings
  // At this point, we've downloaded the tile anyway, so we might as well
  // write the stores that allow it, even if the existing tile hasn't expired
  final writeTileToSpecified = provider.storeNames.entries
      .where(
        (e) => switch (e.value) {
          StoreReadWriteBehavior.read => false,
          StoreReadWriteBehavior.readUpdate =>
            intersectedExistingStores.contains(e.key),
          StoreReadWriteBehavior.readUpdateCreate => true,
        },
      )
      .map((e) => e.key);

  final writeTileToIntermediate =
      (provider.otherStoresBehavior == StoreReadWriteBehavior.readUpdate &&
                  existingTile != null
              ? writeTileToSpecified.followedBy(
                  intersectedExistingStores
                      .whereNot((e) => provider.storeNames.containsKey(e)),
                )
              : writeTileToSpecified)
          .toSet()
          .toList(growable: false);

  // Cache tile to necessary stores
  if (writeTileToIntermediate.isNotEmpty ||
      provider.otherStoresBehavior == StoreReadWriteBehavior.readUpdateCreate) {
    currentTLDI?.writeResult = FMTCBackendAccess.internal.writeTile(
      storeNames: writeTileToIntermediate,
      writeAllNotIn: provider.otherStoresBehavior ==
              StoreReadWriteBehavior.readUpdateCreate
          ? provider.storeNames.keys.toList(growable: false)
          : null,
      url: matcherUrl,
      bytes: responseBytes,
      // ignore: unawaited_futures
    )..then((result) {
        final createdIn = result.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(growable: false);

        // Clear out old tiles if the maximum store length has been exceeded
        // We only need to even attempt this if the number of tiles has changed
        if (createdIn.isEmpty) return;

        unawaited(
          FMTCBackendAccess.internal
              .removeOldestTilesAboveLimit(storeNames: createdIn),
        );
      });
  } else {
    currentTLDI?.writeResult = null;
  }

  currentTLDI?.result = TileLoadingDebugResultPath.fetched;

  registerMiss();
  return responseBytes;
}
