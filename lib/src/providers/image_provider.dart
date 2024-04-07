// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

import '../../flutter_map_tile_caching.dart';
import '../backend/export_internal.dart';
import '../misc/obscure_query_params.dart';

/// A specialised [ImageProvider] that uses FMTC internals to enable browse
/// caching
class FMTCImageProvider extends ImageProvider<FMTCImageProvider> {
  /// Create a specialised [ImageProvider] that uses FMTC internals to enable
  /// browse caching
  FMTCImageProvider({
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
  /// Used with [finishedLoadingBytes] to safely dispose of the `httpClient` only
  /// after all tiles have loaded.
  final void Function() finishedLoadingBytes;

  @override
  ImageStreamCompleter loadImage(
    FMTCImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: coords.toString(),
      informationCollector: () => [
        DiagnosticsProperty('Store name', provider.storeName),
        DiagnosticsProperty('Tile coordinates', coords),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  Future<Codec> _loadAsync(
    FMTCImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    Future<Never> finishWithError(FMTCBrowsingError err) async {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());
      finishedLoadingBytes();

      provider.settings.errorHandler?.call(err);
      throw err;
    }

    Future<Codec> finishSuccessfully({
      required Uint8List bytes,
      required bool cacheHit,
    }) async {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());
      finishedLoadingBytes();

      unawaited(
        FMTCBackendAccess.internal
            .registerHitOrMiss(storeName: provider.storeName, hit: cacheHit),
      );
      return decode(await ImmutableBuffer.fromUint8List(bytes));
    }

    Future<Codec?> attemptFinishViaAltStore(String matcherUrl) async {
      if (provider.settings.fallbackToAlternativeStore) {
        final existingTileAltStore =
            await FMTCBackendAccess.internal.readTile(url: matcherUrl);
        if (existingTileAltStore == null) return null;
        return finishSuccessfully(
          bytes: existingTileAltStore.bytes,
          cacheHit: false,
        );
      }
      return null;
    }

    startedLoading();

    final networkUrl = provider.getTileUrl(coords, options);
    final matcherUrl = obscureQueryParams(
      url: networkUrl,
      obscuredQueryParams: provider.settings.obscuredQueryParams,
    );

    final existingTile = await FMTCBackendAccess.internal.readTile(
      url: matcherUrl,
      storeName: provider.storeName,
    );

    final needsCreating = existingTile == null;
    final needsUpdating = !needsCreating &&
        (provider.settings.behavior == CacheBehavior.onlineFirst ||
            (provider.settings.cachedValidDuration != Duration.zero &&
                DateTime.timestamp().millisecondsSinceEpoch -
                        existingTile.lastModified.millisecondsSinceEpoch >
                    provider.settings.cachedValidDuration.inMilliseconds));

    // Prepare a list of image bytes and prefill if there's already a cached
    // tile available
    Uint8List? bytes;
    if (!needsCreating) bytes = existingTile.bytes;

    // If there is a cached tile that's in date available, use it
    if (!needsCreating && !needsUpdating) {
      return finishSuccessfully(bytes: bytes!, cacheHit: true);
    }

    // If a tile is not available and cache only mode is in use, just fail
    // before attempting a network call
    if (provider.settings.behavior == CacheBehavior.cacheOnly &&
        needsCreating) {
      final codec = await attemptFinishViaAltStore(matcherUrl);
      if (codec != null) return codec;

      return finishWithError(
        FMTCBrowsingError(
          type: FMTCBrowsingErrorType.missingInCacheOnlyMode,
          networkUrl: networkUrl,
          matcherUrl: matcherUrl,
        ),
      );
    }

    // Setup a network request for the tile & handle network exceptions
    final request = Request('GET', Uri.parse(networkUrl))
      ..headers.addAll(provider.headers);
    final StreamedResponse response;
    try {
      response = await provider.httpClient.send(request);
    } catch (e) {
      if (!needsCreating) {
        return finishSuccessfully(bytes: bytes!, cacheHit: false);
      }

      final codec = await attemptFinishViaAltStore(matcherUrl);
      if (codec != null) return codec;

      return finishWithError(
        FMTCBrowsingError(
          type: e is SocketException
              ? FMTCBrowsingErrorType.noConnectionDuringFetch
              : FMTCBrowsingErrorType.unknownFetchException,
          networkUrl: networkUrl,
          matcherUrl: matcherUrl,
          request: request,
          originalError: e,
        ),
      );
    }

    // Check whether the network response is not 200 OK
    if (response.statusCode != 200) {
      if (!needsCreating) {
        return finishSuccessfully(bytes: bytes!, cacheHit: false);
      }

      final codec = await attemptFinishViaAltStore(matcherUrl);
      if (codec != null) return codec;

      return finishWithError(
        FMTCBrowsingError(
          type: FMTCBrowsingErrorType.negativeFetchResponse,
          networkUrl: networkUrl,
          matcherUrl: matcherUrl,
          request: request,
          response: response,
        ),
      );
    }

    // Extract the image bytes from the streamed network response
    final bytesBuilder = BytesBuilder(copy: false);
    await for (final byte in response.stream) {
      bytesBuilder.add(byte);
      chunkEvents.add(
        ImageChunkEvent(
          cumulativeBytesLoaded: bytesBuilder.length,
          expectedTotalBytes: response.contentLength,
        ),
      );
    }
    final responseBytes = bytesBuilder.takeBytes();

    // Perform a secondary check to ensure that the bytes recieved actually
    // encode a valid image
    late final bool isValidImageData;
    try {
      isValidImageData = (await (await instantiateImageCodec(
            responseBytes,
            targetWidth: 8,
            targetHeight: 8,
          ))
                  .getNextFrame())
              .image
              .width >
          0;
    } catch (e) {
      isValidImageData = false;
    }
    if (!isValidImageData) {
      if (!needsCreating) {
        return finishSuccessfully(bytes: bytes!, cacheHit: false);
      }

      final codec = await attemptFinishViaAltStore(matcherUrl);
      if (codec != null) return codec;

      return finishWithError(
        FMTCBrowsingError(
          type: FMTCBrowsingErrorType.invalidImageData,
          networkUrl: networkUrl,
          matcherUrl: matcherUrl,
          request: request,
          response: response,
        ),
      );
    }

    // Cache the tile retrieved from the network response
    unawaited(
      FMTCBackendAccess.internal.writeTile(
        storeName: provider.storeName,
        url: matcherUrl,
        bytes: responseBytes,
      ),
    );

    // Clear out old tiles if the maximum store length has been exceeded
    if (needsCreating && provider.settings.maxStoreLength != 0) {
      unawaited(
        FMTCBackendAccess.internal.removeOldestTilesAboveLimit(
          storeName: provider.storeName,
          tilesLimit: provider.settings.maxStoreLength,
        ),
      );
    }

    return finishSuccessfully(bytes: responseBytes, cacheHit: false);
  }

  @override
  Future<FMTCImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<FMTCImageProvider>(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCImageProvider &&
          other.runtimeType == runtimeType &&
          other.coords == coords &&
          other.provider == provider &&
          other.options == options);

  @override
  int get hashCode => Object.hash(coords, provider, options);
}
