import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

import '../fmtc.dart';
import '../misc/cache_behavior.dart';
import '../misc/validate.dart';
import '../settings/tile_provider_settings.dart';
import 'exts.dart';
import 'image_provider.dart';
import 'store/directory.dart';

/// 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayerOptions]
class FMTCTileProvider extends TileProvider {
  /// The store directory attached to this provider
  final StoreDirectory storeDirectory;

  /// The tile provider settings to use
  ///
  /// Defaults to the one provided by [FMTCSettings] when initialising [FlutterMapTileCaching].
  final FMTCTileProviderSettings settings;

  /// Used internally for browsing-caused tile requests
  final _httpClient = Client();

  /// 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayerOptions]
  ///
  /// Usually created from the store directory chain, eg. [StoreDirectory.getTileProvider].
  ///
  /// This contains the logic for the tile provider, such as browse caching and using bulk downloaded tiles.
  FMTCTileProvider({
    required this.storeDirectory,
    required FMTCTileProviderSettings? settings,
  }) : settings =
            settings ?? FMTC.instance.settings.defaultTileProviderSettings;

  /// Closes the open [Client] - this will make the provider unable to perform network requests
  @override
  void dispose() {
    super.dispose();
    _httpClient.close();
  }

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to cache for later (dependent on the [CacheBehavior])
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) =>
      FMTCImageProvider(
        provider: this,
        options: options,
        coords: coords,
        httpClient: _httpClient,
      );

  /// Check whether a specified tile is cached in the current store synchronously
  bool checkTileCached({
    required Coords<num> coords,
    required TileLayerOptions options,
    String? customURL,
  }) =>
      (storeDirectory.access.tiles >>>
              FMTCSafeFilesystemString.sanitiser(
                inputString: customURL ?? getTileUrl(coords, options),
                throwIfInvalid: false,
              ))
          .existsSync();

  /// Check whether a specified tile is cached in the current store asynchronously
  Future<bool> checkTileCachedAsync({
    required Coords<num> coords,
    required TileLayerOptions options,
    String? customURL,
  }) async =>
      (storeDirectory.access.tiles >>>
              FMTCSafeFilesystemString.sanitiser(
                inputString: customURL ?? getTileUrl(coords, options),
                throwIfInvalid: false,
              ))
          .exists();
}
