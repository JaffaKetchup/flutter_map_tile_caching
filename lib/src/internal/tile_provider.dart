import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

import '../fmtc.dart';
import '../misc/cache_behavior.dart';
import 'image_provider.dart';
import 'store/directory.dart';

/// Settings for an [FMTCTileProvider]
class FMTCTileProviderSettings {
  /// The behavior method to get and cache a tile
  ///
  /// Defaults to [CacheBehavior.cacheFirst] - get tiles from the local cache, going on the Internet to update the cached tile if it has expired ([cachedValidDuration] has passed).
  final CacheBehavior behavior;

  /// The duration until a tile expires and needs to be fetched again when browsing. Also called `validDuration`.
  ///
  /// Defaults to 16 days, set to [Duration.zero] to disable.
  final Duration cachedValidDuration;

  /// The maximum number of tiles allowed in a cache store (only whilst 'browsing' - see below) before the oldest tile gets deleted. Also called `maxTiles`.
  ///
  /// Only applies to 'browse caching', ie. downloading regions will bypass this limit. This can be computationally expensive as it potentially involves sorting through this many files to find the oldest file.
  ///
  /// Please note that this limit is a 'suggestion'. Due to the nature of the application, it is difficult to set a hard limit on a the store's length. Therefore, fast browsing may go above this limit.
  ///
  /// Defaults to 0 disabled.
  final int maxStoreLength;

  /// Create settings for an [FMTCTileProvider]
  FMTCTileProviderSettings({
    this.behavior = CacheBehavior.cacheFirst,
    this.cachedValidDuration = const Duration(days: 16),
    this.maxStoreLength = 0,
  });
}

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
}
