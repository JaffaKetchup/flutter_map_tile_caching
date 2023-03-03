// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:isar/isar.dart';
import 'package:queue/queue.dart';

import '../../flutter_map_tile_caching.dart';
import '../db/defs/metadata.dart';
import '../db/defs/store_descriptor.dart';
import '../db/defs/tile.dart';
import '../db/registry.dart';
import '../db/tools.dart';

/// A specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
class FMTCImageProvider extends ImageProvider<FMTCImageProvider> {
  /// An instance of the [FMTCTileProvider] in use
  final FMTCTileProvider provider;

  /// An instance of the [TileLayer] in use
  final TileLayer options;

  /// The coordinates of the tile to be fetched
  final Coords<num> coords;

  final Isar _db;

  static final _removeOldestQueue = Queue(timeout: const Duration(seconds: 1));
  static final _cacheHitsQueue = Queue();
  static final _cacheMissesQueue = Queue();

  /// Create a specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
  FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
  }) : _db = FMTCRegistry.instance(provider.storeDirectory.storeName);

  @override
  ImageStreamCompleter loadBuffer(
    FMTCImageProvider key,
    DecoderBufferCallback decode,
  ) {
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
    required DecoderBufferCallback decode,
    required StreamController<ImageChunkEvent> chunkEvents,
  }) async {
    Future<void> cacheHitMiss({
      required bool hit,
    }) =>
        (hit ? _cacheHitsQueue : _cacheMissesQueue).add(() async {
          if (_db.isOpen) {
            await _db.writeTxn(() async {
              final store =
                  _db.isOpen ? (await _db.storeDescriptor.get(0)) : null;
              if (store == null) return;
              if (hit) store.hits += 1;
              if (!hit) store.misses += 1;
              await _db.storeDescriptor.put(store);
            });
          }
        });

    Future<Codec> finish({
      Uint8List? bytes,
      String? throwError,
      FMTCBrowsingErrorType? throwErrorType,
      bool? cacheHit,
    }) async {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());

      if (cacheHit != null) unawaited(cacheHitMiss(hit: cacheHit));

      if (throwError != null) {
        try {
          throw FMTCBrowsingError(throwError, throwErrorType!);
        } on FMTCBrowsingError catch (e) {
          provider.settings.errorHandler?.call(e);
          rethrow;
        }
      }

      if (bytes != null) {
        return decode(await ImmutableBuffer.fromUint8List(bytes));
      }

      throw ArgumentError(
        '`finish` was called with an invalid combination of arguments, or a fall-through situation occurred.',
      );
    }

    final networkUrl = provider.getTileUrl(coords, options);
    final matcherUrl = provider.settings.obscureQueryParams(networkUrl);

    final existingTile = await _db.tiles.get(DatabaseTools.hash(matcherUrl));

    final bool needsCreating = existingTile == null;
    final bool needsUpdating = needsCreating
        ? false
        : provider.settings.behavior == CacheBehavior.onlineFirst ||
            (provider.settings.cachedValidDuration != Duration.zero &&
                DateTime.now().millisecondsSinceEpoch -
                        existingTile.lastModified.millisecondsSinceEpoch >
                    provider.settings.cachedValidDuration.inMilliseconds);

    // DEBUG ONLY
    /*
    print('---------');
    print(networkUrl);
    print(matcherUrl);
    print('   Store: ${provider.storeDirectory.storeName}');
    print('   Existing ID: ${existingTile?.id ?? 'None'}');
    print('   Needs Updating & Not Creating: $needsUpdating');
    */

    // Get any existing bytes from the tile, if it exists
    Uint8List? bytes;
    if (!needsCreating) bytes = Uint8List.fromList(existingTile.bytes);

    // IF network is disabled & the tile does not exist THEN throw an error
    if (provider.settings.behavior == CacheBehavior.cacheOnly &&
        needsCreating) {
      return finish(
        throwError:
            'Failed to load the tile from the cache because it was missing.',
        throwErrorType: FMTCBrowsingErrorType.missingInCacheOnlyMode,
        cacheHit: false,
      );
    }

    // IF network is enabled & (the tile does not exist | needs updating) THEN download the tile | throw an error
    if (needsCreating || needsUpdating) {
      final HttpClientResponse response;

      // Try to get a response from a server, throwing an error if not possible & the tile does not exist
      try {
        final request = await provider.httpClient.getUrl(Uri.parse(networkUrl));
        provider.headers.forEach(
          (k, v) => request.headers.add(k, v, preserveHeaderCase: true),
        );
        response = await request.close();
      } catch (err) {
        return finish(
          bytes: !needsCreating ? bytes : null,
          throwError: needsCreating
              ? 'Failed to load the tile from the cache or the network because it was missing from the cache and a connection to the server could not be established.'
              : null,
          throwErrorType: FMTCBrowsingErrorType.noConnectionDuringFetch,
          cacheHit: false,
        );
      }

      // Check for an OK HTTP status code, throwing an error if not possible & the tile does not exist
      if (response.statusCode != 200) {
        return finish(
          bytes: !needsCreating ? bytes : null,
          throwError: needsCreating
              ? 'Failed to load the tile from the cache or the network because it was missing from the cache and the server responded with a HTTP code other than 200 OK.'
              : null,
          throwErrorType: FMTCBrowsingErrorType.negativeFetchResponse,
          cacheHit: false,
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

      // Cache the tile asynchronously
      unawaited(
        _db.writeTxn(
          () => _db.tiles.put(DbTile(url: matcherUrl, bytes: bytes!)),
        ),
      );

      // If an new tile was created over the tile limit, delete the oldest tile
      if (needsCreating && provider.settings.maxStoreLength != 0) {
        unawaited(
          _removeOldestQueue.add(
            () => compute(
              _removeOldestTile,
              [
                provider.storeDirectory.storeName,
                provider.settings.maxStoreLength,
              ],
            ),
          ),
        );
      }

      return finish(bytes: bytes, cacheHit: false);
    }

    // IF tile exists & does not need updating THEN return the existing tile
    return finish(bytes: bytes, cacheHit: true);
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
  int get hashCode => Object.hashAllUnordered([
        coords.hashCode,
        provider.hashCode,
        options.hashCode,
      ]);
}

Future<void> _removeOldestTile(List<Object> args) async {
  final db = Isar.openSync(
    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
    name: DatabaseTools.hash(args[0] as String).toString(),
    inspector: false,
  );

  db.writeTxnSync(
    () => db.tiles.deleteAllSync(
      db.tiles
          .where()
          .anyLastModified()
          .limit(
            (db.tiles.countSync() - (args[1] as int))
                .clamp(0, double.maxFinite)
                .toInt(),
          )
          .findAllSync()
          .map((t) => t.id)
          .toList(),
    ),
  );

  await db.close();
}

/// An [Exception] indicating that there was an error retrieving tiles to be
/// displayed on the map
///
/// These can usually be safely ignored, as they simply represent a fall
/// through of all valid/possible cases, but you may wish to handle them
/// anyway using [FMTCTileProviderSettings.errorHandler].
///
/// Always thrown from within [FMTCImageProvider] generated from
/// [FMTCTileProvider]. The [message] further indicates the reason, and will
/// depend on the current caching behaviour. The [type] represents the same
/// message in a way that is easy to parse/handle.
class FMTCBrowsingError implements Exception {
  /// Friendly message
  final String message;

  /// Programmatic error descriptor
  final FMTCBrowsingErrorType type;

  /// An [Exception] indicating that there was an error retrieving tiles to be
  /// displayed on the map
  ///
  /// These can usually be safely ignored, as they simply represent a fall
  /// through of all valid/possible cases, but you may wish to handle them
  /// anyway using [FMTCTileProviderSettings.errorHandler].
  ///
  /// Always thrown from within [FMTCImageProvider] generated from
  /// [FMTCTileProvider]. The [message] further indicates the reason, and will
  /// depend on the current caching behaviour. The [type] represents the same
  /// message in a way that is easy to parse/handle.
  FMTCBrowsingError(this.message, this.type);

  @override
  String toString() => 'FMTCBrowsingError: $message';
}

/// Pragmatic error descriptor for a [FMTCBrowsingError.message]
///
/// See documentation on that object for more information.
enum FMTCBrowsingErrorType {
  /// Paired with friendly message:
  /// "Failed to load the tile from the cache because it was missing."
  missingInCacheOnlyMode,

  /// Paired with friendly message:
  /// "Failed to load the tile from the cache or the network because it was
  /// missing from the cache and a connection to the server could not be
  /// established."
  noConnectionDuringFetch,

  /// Paired with friendly message:
  /// "Failed to load the tile from the cache or the network because it was
  /// missing from the cache and the server responded with a HTTP code other than
  /// 200 OK."
  negativeFetchResponse,
}
