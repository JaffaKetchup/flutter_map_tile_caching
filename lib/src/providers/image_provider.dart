// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A specialised [ImageProvider] that uses FMTC internals to enable browse
/// caching
///
/// TODO: Improve hits and misses
/// TODO: Debug tile output
class _FMTCImageProvider extends ImageProvider<_FMTCImageProvider> {
  /// Create a specialised [ImageProvider] that uses FMTC internals to enable
  /// browse caching
  _FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
    required this.startedLoading,
    required this.finishedLoadingBytes,
  });

  /// An instance of the [FMTCTileProvider] in use
  final FMTCTileProvider provider;

  /// An instance of the [TileLayer] in use
  final TileLayer options;

  /// The coordinates of the tile to be fetched
  final TileCoordinates coords;

  /// Function invoked when the image starts loading (not from cache)
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the `httpClient` only
  /// after all tiles have loaded.
  final void Function() startedLoading;

  /// Function invoked when the image completes loading bytes from the network
  ///
  /// Used with [startedLoading] to safely dispose of the `httpClient` only
  /// after all tiles have loaded.
  final void Function() finishedLoadingBytes;

  @override
  ImageStreamCompleter loadImage(
    _FMTCImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: coords.toString(),
      informationCollector: () => [
        DiagnosticsProperty('Store names', provider.storeNames),
        DiagnosticsProperty('Tile coordinates', coords),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  Future<Codec> _loadAsync(
    _FMTCImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    void close() {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());
      finishedLoadingBytes();
    }

    startedLoading();

    final Uint8List bytes;
    try {
      bytes = await getBytes(
        coords: coords,
        options: options,
        provider: provider,
        chunkEvents: chunkEvents,
      );
    } catch (err, stackTrace) {
      close();
      if (err is FMTCBrowsingError) {
        final handlerResult = provider.settings.errorHandler?.call(err);
        if (handlerResult != null) {
          return instantiateImageCodecFromBuffer(handlerResult);
        }
      }
      Error.throwWithStackTrace(err, stackTrace);
    }

    close();
    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }

  /// {@template fmtc.imageProvider.getBytes}
  /// Use FMTC's caching logic to get the bytes of the specific tile (at
  /// [coords]) with the specified [TileLayer] options and [FMTCTileProvider]
  /// provider
  ///
  /// Used internally by [_FMTCImageProvider._loadAsync].
  ///
  /// However, can also be used externally to integrate FMTC caching into a 3rd
  /// party [TileProvider], other than [FMTCTileProvider]. For example, this
  /// enables partial compatibility with `VectorTileProvider`s. For more details
  /// about compatibility with vector tiles, check the online documentation.
  ///
  /// ---
  ///
  /// [requireValidImage] should be left `true` as default when the bytes will
  /// form a valid image that Flutter can decode. Set it `false` when the bytes
  /// are not decodable by Flutter - for example with vector tiles. Invalid
  /// images are never written to the cache. If this is `true`, and the image is
  /// invalid, an [FMTCBrowsingError] with sub-category
  /// [FMTCBrowsingErrorType.invalidImageData] will be thrown - if `false`, then
  /// FMTC will not throw an error, but Flutter will if the bytes are attempted
  /// to be decoded.
  ///
  /// [chunkEvents] is intended to be passed when this is being used inside
  /// another [ImageProvider]. Chunk events will be added to it as bytes load.
  /// It will not be closed by this method.
  /// {@endtemplate}
  static Future<Uint8List> getBytes({
    required TileCoordinates coords,
    required TileLayer options,
    required FMTCTileProvider provider,
    StreamController<ImageChunkEvent>? chunkEvents,
    bool requireValidImage = true,
  }) async {
    void registerHit(List<String> storeNames) {
      if (provider.settings.recordHitsAndMisses) {
        FMTCBackendAccess.internal
            .registerHitOrMiss(storeNames: storeNames, hit: true);
      }
    }

    void registerMiss() {
      if (provider.settings.recordHitsAndMisses) {
        FMTCBackendAccess.internal.registerHitOrMiss(
          storeNames: provider._getSpecifiedStoresOrNull(), // TODO: Verify
          hit: false,
        );
      }
    }

    final networkUrl = provider.getTileUrl(coords, options);
    final matcherUrl = obscureQueryParams(
      url: networkUrl,
      obscuredQueryParams: provider.settings.obscuredQueryParams,
    );

    final (
      tile: existingTile,
      intersectedStoreNames: intersectedExistingStores,
      allStoreNames: allExistingStores,
    ) = await FMTCBackendAccess.internal.readTile(
      url: matcherUrl,
      storeNames: provider._getSpecifiedStoresOrNull(),
    );

    const useUnspecifiedAsLastResort = true;

    final tileExistsInUnspecifiedStoresOnly = existingTile != null &&
        useUnspecifiedAsLastResort &&
        provider.storeNames.keys
            .toSet()
            .union(allExistingStores.toSet())
            .isEmpty;

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
    if (existingTile != null &&
        !needsUpdating &&
        !tileExistsInUnspecifiedStoresOnly) {
      registerHit(intersectedExistingStores);
      return bytes!;
    }

    // If a tile is not available and cache only mode is in use, just fail
    // before attempting a network call
    if (provider.settings.behavior == CacheBehavior.cacheOnly) {
      if (tileExistsInUnspecifiedStoresOnly) {
        registerMiss();
        return bytes!;
      }
      if (existingTile == null) {
        throw FMTCBrowsingError(
          type: FMTCBrowsingErrorType.missingInCacheOnlyMode,
          networkUrl: networkUrl,
          matcherUrl: matcherUrl,
        );
      }
    }

    // Setup a network request for the tile & handle network exceptions
    final request = http.Request('GET', Uri.parse(networkUrl))
      ..headers.addAll(provider.headers);
    final http.StreamedResponse response;
    try {
      response = await provider.httpClient.send(request);
    } catch (e) {
      if (existingTile != null) {
        registerMiss();
        return bytes!;
      }

      throw FMTCBrowsingError(
        type: e is SocketException
            ? FMTCBrowsingErrorType.noConnectionDuringFetch
            : FMTCBrowsingErrorType.unknownFetchException,
        networkUrl: networkUrl,
        matcherUrl: matcherUrl,
        request: request,
        originalError: e,
      );
    }

    // Check whether the network response is not 200 OK
    if (response.statusCode != 200) {
      if (existingTile != null) {
        registerMiss();
        return bytes!;
      }

      throw FMTCBrowsingError(
        type: FMTCBrowsingErrorType.negativeFetchResponse,
        networkUrl: networkUrl,
        matcherUrl: matcherUrl,
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
          registerMiss();
          return bytes!;
        }

        throw FMTCBrowsingError(
          type: FMTCBrowsingErrorType.invalidImageData,
          networkUrl: networkUrl,
          matcherUrl: matcherUrl,
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
        provider.otherStoresBehavior == StoreReadWriteBehavior.readUpdate &&
                existingTile != null
            ? writeTileToSpecified.followedBy(
                intersectedExistingStores
                    .whereNot((e) => provider.storeNames.containsKey(e)),
              )
            : writeTileToSpecified;

    // Cache tile to necessary stores
    if (writeTileToIntermediate.isNotEmpty ||
        provider.otherStoresBehavior ==
            StoreReadWriteBehavior.readUpdateCreate) {
      unawaited(
        FMTCBackendAccess.internal
            .writeTile(
          storeNames: writeTileToIntermediate.toSet().toList(growable: false),
          writeAllNotIn: provider.otherStoresBehavior ==
                  StoreReadWriteBehavior.readUpdateCreate
              ? provider.storeNames.keys.toList(growable: false)
              : null,
          url: matcherUrl,
          bytes: responseBytes,
        )
            .then((createdIn) {
          // Clear out old tiles if the maximum store length has been exceeded
          // We only need to even attempt this if the number of tiles has changed
          if (createdIn.isEmpty) return;
          FMTCBackendAccess.internal
              .removeOldestTilesAboveLimit(storeNames: createdIn);
        }),
      );
    }

    registerMiss();
    return responseBytes;
  }

  @override
  Future<_FMTCImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FMTCImageProvider>(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FMTCImageProvider &&
          other.runtimeType == runtimeType &&
          other.coords == coords &&
          other.provider == provider &&
          other.options == options);

  @override
  int get hashCode => Object.hash(coords, provider, options);
}
