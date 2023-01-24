// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
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

  /// A HTTP client used to send requests
  final HttpClient httpClient;

  /// Custom headers to send with each request
  final Map<String, String> headers;

  /// Used internally to safely and efficiently enforce the `settings.maxStoreLength`
  static final Queue removeOldestQueue =
      Queue(timeout: const Duration(seconds: 1));

  /// Used internally to safely and efficiently update the cache hits statistic
  static final Queue cacheHitsQueue = Queue();

  /// Used internally to safely and efficiently update the cache misses statistic
  static final Queue cacheMissesQueue = Queue();

  /// Shorthand for `provider.settings`
  late final FMTCTileProviderSettings settings;

  /// Create a specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
  FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
    required this.httpClient,
    required this.headers,
  })  : settings = provider.settings,
        _storeId = DatabaseTools.hash(provider.storeDirectory.storeName);

  final int _storeId;
  Isar get _tiles => FMTCRegistry.instance.storeDatabases[_storeId]!;

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
        (hit ? cacheHitsQueue : cacheMissesQueue).add(() async {
          final db = FMTCRegistry.instance.storeDatabases[_storeId]!;

          await db.writeTxn(() async {
            final store = (await db.storeDescriptor.get(0))!;
            if (hit) store.hits += 1;
            if (!hit) store.misses += 1;
            await db.storeDescriptor.put(store);
          });
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
          if (settings.errorHandler != null) {
            settings.errorHandler!(e);
          } else {
            rethrow;
          }
        }
      }

      if (bytes != null) {
        return decode(await ImmutableBuffer.fromUint8List(bytes));
      }

      throw FallThroughError();
    }

    final String url = provider.getTileUrl(coords, options);
    final DbTile? existingTile =
        await _tiles.tiles.get(DatabaseTools.hash(url));

    // Logic to check whether the tile needs creating or updating
    final bool needsCreating = existingTile == null;
    final bool needsUpdating = needsCreating
        ? false
        : settings.behavior == CacheBehavior.onlineFirst ||
            (settings.cachedValidDuration != Duration.zero &&
                DateTime.now().millisecondsSinceEpoch -
                        existingTile.lastModified.millisecondsSinceEpoch >
                    settings.cachedValidDuration.inMilliseconds);

    // Get any existing bytes from the tile, if it exists
    Uint8List? bytes;
    if (!needsCreating) bytes = Uint8List.fromList(existingTile.bytes);

    // IF network is disabled & the tile does not exist THEN throw an error
    if (settings.behavior == CacheBehavior.cacheOnly && needsCreating) {
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
        _tiles
            .writeTxn(() => _tiles.tiles.put(DbTile(url: url, bytes: bytes!))),
      );

      // If an new tile was created over the tile limit, delete the oldest tile
      if (needsCreating && settings.maxStoreLength != 0) {
        unawaited(
          removeOldestQueue.add(
            () => compute(
              _removeOldestTile,
              [provider.storeDirectory.storeName, settings.maxStoreLength],
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
      (other is FMTCImageProvider && other.coords == coords);

  @override
  int get hashCode => coords.hashCode;
}

Future<void> _removeOldestTile(List<Object> args) async {
  final db = Isar.openSync(
    [DbTileSchema, DbMetadataSchema],
    name: DatabaseTools.hash(args[0] as String).toString(),
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
