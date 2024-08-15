// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

Future<Uint8List> _internalGetBytes({
  required TileCoordinates coords,
  required TileLayer options,
  required FMTCTileProvider provider,
  required bool requireValidImage,
  required _TLIRConstructor? currentTLIR,
}) async {
  void registerHit(List<String> storeNames) {
    currentTLIR?.hitOrMiss = true;
    if (provider.recordHitsAndMisses) {
      FMTCBackendAccess.internal
          .registerHitOrMiss(storeNames: storeNames, hit: true);
    }
  }

  void registerMiss() {
    currentTLIR?.hitOrMiss = false;
    if (provider.recordHitsAndMisses) {
      FMTCBackendAccess.internal.registerHitOrMiss(
        storeNames: provider._getSpecifiedStoresOrNull(), // TODO: Verify
        hit: false,
      );
    }
  }

  final networkUrl = provider.getTileUrl(coords, options);
  final matcherUrl = provider.urlTransformer(networkUrl);

  currentTLIR?.networkUrl = networkUrl;
  currentTLIR?.storageSuitableUID = matcherUrl;

  late final DateTime cacheFetchStartTime;
  if (currentTLIR != null) cacheFetchStartTime = DateTime.now();

  final (
    tile: existingTile,
    intersectedStoreNames: intersectedExistingStores,
    allStoreNames: allExistingStores,
  ) = await FMTCBackendAccess.internal.readTile(
    url: matcherUrl,
    storeNames: provider._getSpecifiedStoresOrNull(),
  );

  currentTLIR?.cacheFetchDuration =
      DateTime.now().difference(cacheFetchStartTime);

  if (allExistingStores.isNotEmpty) {
    currentTLIR?.existingStores = allExistingStores;
  }

  final tileExistsInUnspecifiedStoresOnly = existingTile != null &&
      provider.useOtherStoresAsFallbackOnly &&
      provider.storeNames.keys
          .toSet()
          .union(
            allExistingStores.toSet(),
          ) // TODO: Verify (intersect? simplify?)
          .isEmpty;

  currentTLIR?.tileExistsInUnspecifiedStoresOnly =
      tileExistsInUnspecifiedStoresOnly;

  // Prepare a list of image bytes and prefill if there's already a cached
  // tile available
  Uint8List? bytes;
  if (existingTile != null) bytes = existingTile.bytes;

  // If there is a cached tile that's in date available, use it
  final needsUpdating = existingTile != null &&
      (provider.loadingStrategy == BrowseLoadingStrategy.onlineFirst ||
          (provider.cachedValidDuration != Duration.zero &&
              DateTime.timestamp().millisecondsSinceEpoch -
                      existingTile.lastModified.millisecondsSinceEpoch >
                  provider.cachedValidDuration.inMilliseconds));

  currentTLIR?.needsUpdating = needsUpdating;

  if (existingTile != null &&
      !needsUpdating &&
      !tileExistsInUnspecifiedStoresOnly) {
    currentTLIR?.resultPath =
        TileLoadingInterceptorResultPath.perfectFromStores;

    registerHit(intersectedExistingStores);
    return bytes!;
  }

  // If a tile is not available and cache only mode is in use, just fail
  // before attempting a network call
  if (provider.loadingStrategy == BrowseLoadingStrategy.cacheOnly) {
    if (existingTile != null) {
      currentTLIR?.resultPath =
          TileLoadingInterceptorResultPath.cacheOnlyFromOtherStores;

      registerMiss();
      return bytes!;
    }

    throw FMTCBrowsingError(
      type: FMTCBrowsingErrorType.missingInCacheOnlyMode,
      networkUrl: networkUrl,
      storageSuitableUID: matcherUrl,
    );

    // TODO: remove below
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
  final http.Response response;

  late final DateTime networkFetchStartTime;
  if (currentTLIR != null) networkFetchStartTime = DateTime.now();

  try {
    response = await provider.httpClient
        .get(Uri.parse(networkUrl), headers: provider.headers);
  } catch (e) {
    if (existingTile != null) {
      currentTLIR?.resultPath = TileLoadingInterceptorResultPath.noFetch;

      registerMiss();
      return bytes!;
    }

    throw FMTCBrowsingError(
      type: e is SocketException
          ? FMTCBrowsingErrorType.noConnectionDuringFetch
          : FMTCBrowsingErrorType.unknownFetchException,
      networkUrl: networkUrl,
      storageSuitableUID: matcherUrl,
      originalError: e,
    );
  }

  currentTLIR?.networkFetchDuration =
      DateTime.now().difference(networkFetchStartTime);

  // Check whether the network response is not 200 OK
  if (response.statusCode != 200) {
    if (existingTile != null) {
      currentTLIR?.resultPath = TileLoadingInterceptorResultPath.noFetch;

      registerMiss();
      return bytes!;
    }

    throw FMTCBrowsingError(
      type: FMTCBrowsingErrorType.negativeFetchResponse,
      networkUrl: networkUrl,
      storageSuitableUID: matcherUrl,
      response: response,
    );
  }

  // Perform a secondary check to ensure that the bytes recieved actually
  // encode a valid image
  if (requireValidImage) {
    late final Object? isValidImageData;

    try {
      isValidImageData = (await (await instantiateImageCodec(
                response.bodyBytes,
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
        currentTLIR?.resultPath = TileLoadingInterceptorResultPath.noFetch;

        registerMiss();
        return bytes!;
      }

      throw FMTCBrowsingError(
        type: FMTCBrowsingErrorType.invalidImageData,
        networkUrl: networkUrl,
        storageSuitableUID: matcherUrl,
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
          BrowseStoreStrategy.read => false,
          BrowseStoreStrategy.readUpdate =>
            intersectedExistingStores.contains(e.key),
          BrowseStoreStrategy.readUpdateCreate => true,
        },
      )
      .map((e) => e.key);

  final writeTileToIntermediate =
      (provider.otherStoresStrategy == BrowseStoreStrategy.readUpdate &&
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
      provider.otherStoresStrategy == BrowseStoreStrategy.readUpdateCreate) {
    currentTLIR?.storesWriteResult = FMTCBackendAccess.internal.writeTile(
      storeNames: writeTileToIntermediate,
      writeAllNotIn:
          provider.otherStoresStrategy == BrowseStoreStrategy.readUpdateCreate
              ? provider.storeNames.keys.toList(growable: false)
              : null,
      url: matcherUrl,
      bytes: response.bodyBytes,
      // ignore: unawaited_futures
    )..then((result) {
        final createdIn =
            result.entries.where((e) => e.value).map((e) => e.key);

        // Clear out old tiles if the maximum store length has been exceeded
        // We only need to even attempt this if the number of tiles has changed
        if (createdIn.isEmpty) return;

        FMTCBackendAccess.internal.removeOldestTilesAboveLimit(
          storeNames: createdIn.toList(growable: false), // TODO: Verify
        );
      });
  }

  currentTLIR?.resultPath = TileLoadingInterceptorResultPath.fetched;

  registerMiss();
  return response.bodyBytes;
}
