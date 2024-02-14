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
import '../misc/obscure_query_params.dart';

/// A specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
class FMTCImageProvider extends ImageProvider<FMTCImageProvider> {
  /// The name of the store associated with this provider
  final String storeName;

  /// An instance of the [FMTCTileProvider] in use
  final FMTCTileProvider provider;

  /// An instance of the [TileLayer] in use
  final TileLayer options;

  /// The coordinates of the tile to be fetched
  final TileCoordinates coords;

  /// Create a specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
  FMTCImageProvider({
    required this.storeName,
    required this.provider,
    required this.options,
    required this.coords,
  });

  FMTCBackendInternal get _backend => FMTC.instance.backend.internal;

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
        DiagnosticsProperty('Store name', storeName),
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
      await evict();

      provider.settings.errorHandler?.call(err);
      throw err;
    }

    Future<Codec> finishSuccessfully({
      required Uint8List bytes,
      required bool cacheHit,
    }) async {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());
      await evict();

      unawaited(_cacheHitMiss(hit: cacheHit));
      return decode(await ImmutableBuffer.fromUint8List(bytes));
    }

    final networkUrl = provider.getTileUrl(coords, options);
    final matcherUrl = obscureQueryParams(
      url: networkUrl,
      obscuredQueryParams: provider.settings.obscuredQueryParams,
    );

    final existingTile = await _backend.readTile(url: matcherUrl);

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
      _backend.writeTile(
        storeName: storeName,
        url: matcherUrl,
        bytes: responseBytes,
      ),
    );

    // Clear out old tiles if the maximum store length has been exceeded
    if (needsCreating && provider.settings.maxStoreLength != 0) {
      // TODO: Check if performance is acceptable without checking limit excess first
      unawaited(
        _backend.removeOldestTilesAboveLimit(
          storeName: storeName,
          tilesLimit: provider.settings.maxStoreLength,
        ),
      );
    }

    return finishSuccessfully(bytes: responseBytes, cacheHit: false);
  }

  Future<void> _cacheHitMiss({required bool hit}) =>
      (hit ? _cacheHitsQueue : _cacheMissesQueue).add(() async {
        if (db.isOpen) {
          await db.writeTxn(() async {
            final store = db.isOpen ? await db.descriptor : null;
            if (store == null) return;
            if (hit) {
              store.hits += 1;
            } else {
              store.misses += 1;
            }
            await db.storeDescriptor.put(store);
          });
        }
      });

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
