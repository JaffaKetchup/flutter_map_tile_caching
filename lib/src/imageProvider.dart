import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p show joinAll;

import 'main.dart';
import 'misc.dart';

/// A specialised [ImageProvider] dedicated to `flutter_map_tile_caching`
class FMTCImageProvider extends ImageProvider<FMTCImageProvider> {
  /// An instance of the [StorageCachingTileProvider] in use
  final StorageCachingTileProvider provider;

  /// An instance of the [TileLayerOptions] in use
  final TileLayerOptions options;

  /// The coordinates of the tile to be fetched
  final Coords<num> coords;

  /// A HTTP client used to send requests
  final http.Client httpClient;

  /// Create a specialised [ImageProvider] dedicated to `flutter_map_tile_caching`
  FMTCImageProvider({
    required this.provider,
    required this.options,
    required this.coords,
    required this.httpClient,
  });

  @override
  ImageStreamCompleter load(FMTCImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
      debugLabel: coords.toString(),
      informationCollector: () sync* {
        yield ErrorDescription('Coordinates: $coords');
      },
    );
  }

  Future<Codec> _loadAsync(DecoderCallback decode) async {
    final String url = provider.getTileUrl(coords, options);
    final File file = File(p.joinAll([provider.storePath, safeFilename(url)]));

    // Logic to check whether the tile needs creating or updating
    final bool needsCreating = !(await file.exists());
    final bool needsUpdating = needsCreating
        ? false
        : provider.behavior == CacheBehavior.onlineFirst ||
            (provider.cachedValidDuration != Duration.zero &&
                DateTime.now().millisecondsSinceEpoch -
                        file.lastModifiedSync().millisecondsSinceEpoch >
                    provider.cachedValidDuration.inMilliseconds);

    // Read the tile file if it exists
    Uint8List? bytes;
    if (!needsCreating) bytes = await file.readAsBytes();

    // IF network is disabled & the tile does not exist THEN throw an error
    if (provider.behavior == CacheBehavior.cacheOnly && needsCreating) {
      PaintingBinding.instance?.imageCache?.evict(this);
      throw 'FMTCBrowsingError: Failed to load the tile from the cache because it was missing.';
    }

    // IF network is enabled & (the tile does not exist | needs updating) THEN download the tile | throw an error
    if (needsCreating || needsUpdating) {
      late final http.Response serverData;

      // Try to get a response from a server, throwing an error if not possible & the tile does not exist
      try {
        serverData = await httpClient.get(Uri.parse(url));
      } catch (err) {
        if (needsCreating) {
          PaintingBinding.instance?.imageCache?.evict(this);
          throw 'FMTCBrowsingError: Failed to load the tile from the cache or the network because it was missing from the cache and a connection to the server could not be established.';
        } else
          return await decode(bytes!);
      }

      // Check for an OK HTTP status code, throwing an error if not possible & the tile does not exist
      if (serverData.statusCode != 200) {
        if (needsCreating) {
          PaintingBinding.instance?.imageCache?.evict(this);
          throw 'FMTCBrowsingError: Failed to load the tile from the cache or the network because it was missing from the cache and the server responded with a HTTP code other than 200 OK.';
        } else
          return await decode(bytes!);
      }

      // Cache the tile in a seperate isolate
      bytes = serverData.bodyBytes;
      compute(writeFile, {
        'filePath': file.absolute.path,
        'bytes': bytes,
      });

      // If an new tile was created over the tile limit, delete the oldest tile
      if (needsCreating)
        compute(deleteOldestFile, {
          'storePath': provider.storePath,
          'maxStoreLength': provider.maxStoreLength,
        });

      return await decode(bytes);
    }

    // IF tile exists & does not need updating THEN return the existing tile
    return await decode(bytes!);
  }

  @override
  Future<FMTCImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FMTCImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is FMTCImageProvider && other.coords == coords;
    return res;
  }

  @override
  int get hashCode => coords.hashCode;
}

void deleteOldestFile(Map<String, dynamic> input) {
  final Directory store = Directory(input['storePath'] as String);
  final int maxStoreLength = input['maxStoreLength'];

  while (true) {
    final List<FileSystemEntity> fileList = store.listSync();

    if (maxStoreLength != 0 && fileList.length > maxStoreLength) {
      fileList.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      try {
        fileList.last.deleteSync();
      } catch (e) {}
    }

    break;
  }
}

void writeFile(Map<String, dynamic> input) {
  final File file = File(input['filePath'] as String);
  final Uint8List bytes = input['bytes'];

  file.createSync();
  file.writeAsBytesSync(bytes);
}
