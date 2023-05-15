// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart';
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
  final TileCoordinates coords;

  /// Configured root directory
  final String directory;

  /// The database to write tiles to
  final Isar db;

  static final _removeOldestQueue = Queue(timeout: const Duration(seconds: 1));
  static final _cacheHitsQueue = Queue();
  static final _cacheMissesQueue = Queue();

  /// Create a specialised [ImageProvider] dedicated to 'flutter_map_tile_caching'
  FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
    required this.directory,
  }) : db = FMTCRegistry.instance(provider.storeDirectory.storeName);

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
        DiagnosticsProperty('Tile coordinates', coords),
        DiagnosticsProperty('Root directory', directory),
        DiagnosticsProperty('Store name', provider.storeDirectory.storeName),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  Future<Codec> _loadAsync(
    FMTCImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    Future<void> cacheHitMiss({required bool hit}) =>
        (hit ? _cacheHitsQueue : _cacheMissesQueue).add(() async {
          if (db.isOpen) {
            await db.writeTxn(() async {
              final store = db.isOpen ? await db.descriptor : null;
              if (store == null) return;
              if (hit) store.hits += 1;
              if (!hit) store.misses += 1;
              await db.storeDescriptor.put(store);
            });
          }
        });

    Future<Codec> finish({
      List<int>? bytes,
      String? throwError,
      FMTCBrowsingErrorType? throwErrorType,
      bool? cacheHit,
    }) async {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      unawaited(chunkEvents.close());

      if (cacheHit != null) unawaited(cacheHitMiss(hit: cacheHit));

      if (throwError != null) {
        await evict();

        final error = FMTCBrowsingError(throwError, throwErrorType!);
        provider.settings.errorHandler?.call(error);
        throw error;
      }

      if (bytes != null) {
        return decode(
          await ImmutableBuffer.fromUint8List(Uint8List.fromList(bytes)),
        );
      }

      throw ArgumentError(
        '`finish` was called with an invalid combination of arguments, or a fall-through situation occurred.',
      );
    }

    final networkUrl = provider.getTileUrl(coords, options);
    final matcherUrl = provider.settings.obscureQueryParams(networkUrl);

    final existingTile = await db.tiles.get(DatabaseTools.hash(matcherUrl));

    final needsCreating = existingTile == null;
    final needsUpdating = !needsCreating &&
        (provider.settings.behavior == CacheBehavior.onlineFirst ||
            (provider.settings.cachedValidDuration != Duration.zero &&
                DateTime.now().millisecondsSinceEpoch -
                        existingTile.lastModified.millisecondsSinceEpoch >
                    provider.settings.cachedValidDuration.inMilliseconds));

    List<int>? bytes;
    if (!needsCreating) bytes = Uint8List.fromList(existingTile.bytes);

    if (provider.settings.behavior == CacheBehavior.cacheOnly &&
        needsCreating) {
      return finish(
        throwError:
            'Failed to load the tile from the cache because it was missing.',
        throwErrorType: FMTCBrowsingErrorType.missingInCacheOnlyMode,
        cacheHit: false,
      );
    }

    if (!needsCreating && !needsUpdating) {
      return finish(bytes: bytes, cacheHit: true);
    }

    final StreamedResponse response;

    try {
      response = await provider.httpClient.send(
        Request('GET', Uri.parse(networkUrl))..headers.addAll(provider.headers),
      );
    } catch (_) {
      return finish(
        bytes: !needsCreating ? bytes : null,
        throwError: needsCreating
            ? 'Failed to load the tile from the cache or the network because it was missing from the cache and a connection to the server could not be established.'
            : null,
        throwErrorType: FMTCBrowsingErrorType.noConnectionDuringFetch,
        cacheHit: false,
      );
    }

    if (response.statusCode != 200) {
      return finish(
        bytes: !needsCreating ? bytes : null,
        throwError: needsCreating
            ? 'Failed to load the tile from the cache or the network because it was missing from the cache and the server responded with a HTTP code of ${response.statusCode}'
            : null,
        throwErrorType: FMTCBrowsingErrorType.negativeFetchResponse,
        cacheHit: false,
      );
    }

    int bytesReceivedLength = 0;
    bytes = [];
    await for (final byte in response.stream) {
      bytesReceivedLength += byte.length;
      bytes.addAll(byte);
      chunkEvents.add(
        ImageChunkEvent(
          cumulativeBytesLoaded: bytesReceivedLength,
          expectedTotalBytes: response.contentLength,
        ),
      );
    }

    unawaited(
      db.writeTxn(() => db.tiles.put(DbTile(url: matcherUrl, bytes: bytes!))),
    );

    if (needsCreating && provider.settings.maxStoreLength != 0) {
      unawaited(
        _removeOldestQueue.add(
          () => compute(
            _removeOldestTile,
            [
              provider.storeDirectory.storeName,
              directory,
              provider.settings.maxStoreLength,
            ],
          ),
        ),
      );
    }

    return finish(bytes: bytes, cacheHit: false);
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

Future<void> _removeOldestTile(List<dynamic> args) async {
  final db = Isar.openSync(
    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
    name: DatabaseTools.hash(args[0]).toString(),
    directory: args[1],
    inspector: false,
  );

  db.writeTxnSync(
    () => db.tiles.deleteAllSync(
      db.tiles
          .where()
          .anyLastModified()
          .limit(
            (db.tiles.countSync() - args[2]).clamp(0, double.maxFinite).toInt(),
          )
          .findAllSync()
          .map((t) => t.id)
          .toList(),
    ),
  );

  await db.close();
}
