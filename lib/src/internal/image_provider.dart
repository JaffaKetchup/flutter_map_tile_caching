import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:queue/queue.dart';

import '../internal/exts.dart';
import '../misc/cache_behavior.dart';
import '../misc/validate.dart';
import '../settings/tile_provider_settings.dart';
import 'tile_provider.dart';

/// A specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
class FMTCImageProvider extends ImageProvider<FMTCImageProvider> {
  /// An instance of the [FMTCTileProvider] in use
  final FMTCTileProvider provider;

  /// An instance of the [TileLayerOptions] in use
  final TileLayerOptions options;

  /// The coordinates of the tile to be fetched
  final Coords<num> coords;

  /// A HTTP client used to send requests
  final HttpClient httpClient;

  /// Custom headers to send with each request
  final Map<String, String> headers;

  /// Used internally to safely and efficiently enforce the `settings.maxStoreLength`
  static final Queue removeOldestQueue =
      Queue(timeout: const Duration(seconds: 1));

  /// Shorthand for `provider.settings`
  late final FMTCTileProviderSettings settings;

  /// Create a specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
  FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
    required this.httpClient,
    required this.headers,
  }) : settings = provider.settings;

  @override
  ImageStreamCompleter load(FMTCImageProvider key, DecoderCallback decode) {
    // ignore: close_sinks
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key: key, decode: decode, chunkEvents: chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: coords.toString(),
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<Coords>('Coordinates', coords),
      ],
    );
  }

  Future<Codec> _loadAsync({
    required FMTCImageProvider key,
    required DecoderCallback decode,
    required StreamController<ImageChunkEvent> chunkEvents,
  }) async {
    Future<Codec> finish({
      Uint8List? bytes,
      String? throwError,
    }) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());
      if (throwError != null) throw _FMTCBrowsingError(throwError);
      if (bytes != null) return decode(bytes);
      throw FallThroughError();
    }

    Future<void> cacheHitMiss({
      required bool hit,
    }) async {
      final File file = provider.storeDirectory.access.stats >>>
          (hit ? 'cacheHits.cache' : 'cacheMisses.cache');
      await file.writeAsString(
        (int.parse(await file.readAsString()) + 1).toString(),
        flush: true,
      );
    }

    final String url = provider.getTileUrl(coords, options);
    final File file = provider.storeDirectory.access.tiles >>>
        FMTCSafeFilesystemString.sanitiser(
          inputString: url,
          throwIfInvalid: false,
        );

    // Logic to check whether the tile needs creating or updating
    final bool needsCreating = !(await file.exists());
    final bool needsUpdating = needsCreating
        ? false
        : settings.behavior == CacheBehavior.onlineFirst ||
            (settings.cachedValidDuration != Duration.zero &&
                DateTime.now().millisecondsSinceEpoch -
                        (await file.lastModified()).millisecondsSinceEpoch >
                    settings.cachedValidDuration.inMilliseconds);

    // Read the tile file if it exists
    Uint8List? bytes;
    if (!needsCreating) bytes = await file.readAsBytes();

    // IF network is disabled & the tile does not exist THEN throw an error
    if (settings.behavior == CacheBehavior.cacheOnly && needsCreating) {
      return finish(
        throwError:
            'Failed to load the tile from the cache because it was missing.',
      );
    }

    // IF network is enabled & (the tile does not exist | needs updating) THEN download the tile | throw an error
    if (needsCreating || needsUpdating) {
      final HttpClientResponse response;

      // Try to get a response from a server, throwing an error if not possible & the tile does not exist
      try {
        final HttpClientRequest request =
            await httpClient.getUrl(Uri.parse(url));
        headers.forEach((k, v) => request.headers.add(k, v));
        response = await request.close();
      } catch (err) {
        return finish(
          bytes: !needsCreating ? bytes : null,
          throwError: needsCreating
              ? 'Failed to load the tile from the cache or the network because it was missing from the cache and a connection to the server could not be established.'
              : null,
        );
      }

      // Check for an OK HTTP status code, throwing an error if not possible & the tile does not exist
      if (response.statusCode != 200) {
        return finish(
          bytes: !needsCreating ? bytes : null,
          throwError: needsCreating
              ? 'Failed to load the tile from the cache or the network because it was missing from the cache and the server responded with a HTTP code other than 200 OK.'
              : null,
        );
      }

      // Read the bytes from the HTTP request response
      bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          chunkEvents.add(
            ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ),
          );
        },
      );

      // Cache the tile in a seperate isolate
      unawaited(file.create().then((_) => file.writeAsBytes(bytes!)));
      if (needsCreating) {
        unawaited(
          provider.storeDirectory.stats.invalidateCachedStatisticsAsync(),
        );
      }

      // If an new tile was created over the tile limit, delete the oldest tile
      if (needsCreating && settings.maxStoreLength != 0) {
        unawaited(
          removeOldestQueue.add(() async {
            int currentIteration = 0;
            bool needToDelete = false;

            File? currentOldestFile;
            DateTime? currentOldestDateTime;

            await for (final FileSystemEntity e
                in provider.storeDirectory.access.tiles.list()) {
              if (e is! File) break;

              currentIteration++;
              if (currentIteration >= settings.maxStoreLength) {
                needToDelete = true;
                continue;
              }

              final DateTime modified = (await e.stat()).modified;

              if (modified.isBefore(currentOldestDateTime ?? DateTime.now())) {
                currentOldestFile = e;
                currentOldestDateTime = modified;
              }
            }

            if (!needToDelete) return;
            await currentOldestFile?.delete();
            await provider.storeDirectory.stats
                .invalidateCachedStatisticsAsync();
          }),
        );
      }

      unawaited(cacheHitMiss(hit: false));
      return finish(bytes: bytes);
    }

    // IF tile exists & does not need updating THEN return the existing tile
    unawaited(cacheHitMiss(hit: true));
    return finish(bytes: bytes);
  }

  @override
  Future<FMTCImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<FMTCImageProvider>(this);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FMTCImageProvider &&
        other.coords == coords &&
        other.provider.storeDirectory.storeName ==
            provider.storeDirectory.storeName;
  }

  @override
  int get hashCode => coords.hashCode;
}

/// An [Exception] indicating that there was an error retrieving tiles to be displayed on the map
///
/// Always thrown from within [FMTCImageProvider] generated from [FMTCTileProvider]. The [message] further indicates the reason, and may depend on the current caching behaviour.
class _FMTCBrowsingError implements Exception {
  final String message;

  /// An [Exception] indicating that there was an error retrieving tiles to be displayed on the map
  ///
  /// Always thrown from within [FMTCImageProvider] generated from [FMTCTileProvider]. The [message] further indicates the reason, and may depend on the current caching behaviour.
  _FMTCBrowsingError(this.message);

  @override
  String toString() => 'FMTCBrowsingError: $message';
}
