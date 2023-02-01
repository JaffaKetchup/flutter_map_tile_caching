// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayer]
class FMTCTileProvider extends TileProvider {
  /// The store directory attached to this provider
  final StoreDirectory storeDirectory;

  /// The tile provider settings to use
  ///
  /// Defaults to the one provided by [FMTCSettings] when initialising [FlutterMapTileCaching].
  final FMTCTileProviderSettings settings;

  /// Used internally for browsing-caused tile requests
  final HttpClient httpClient;

  /// 'flutter_map_tile_caching's custom [TileProvider] for use in a [TileLayer]
  ///
  /// Usually created from the store directory chain, eg. [StoreDirectory.getTileProvider].
  ///
  /// This contains the logic for the tile provider, such as browse caching and using bulk downloaded tiles.
  FMTCTileProvider({
    required this.storeDirectory,
    required FMTCTileProviderSettings? settings,
    super.headers,
    HttpClient? httpClient,
  })  : settings =
            settings ?? FMTC.instance.settings.defaultTileProviderSettings,
        httpClient = httpClient ?? HttpClient()
          ..userAgent = null;

  /// Closes the open [HttpClient] - this will make the provider unable to perform network requests
  @override
  void dispose() {
    super.dispose();
    httpClient.close();
  }

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to cache for later (dependent on the [CacheBehavior])
  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) =>
      FMTCImageProvider(
        provider: this,
        options: options,
        coords: coords,
        httpClient: httpClient,
        headers: {
          ...headers,
          'User-Agent': headers['User-Agent'] == null
              ? 'flutter_map_tile_caching for flutter_map (unknown)'
              : 'flutter_map_tile_caching for ${headers['User-Agent']}',
        },
      );

  IsarCollection<DbTile> get _tiles => FMTCRegistry.instance
      .storeDatabases[DatabaseTools.hash(storeDirectory.storeName)]!.tiles;

  /// Check whether a specified tile is cached in the current store synchronously
  bool checkTileCached({
    required Coords<num> coords,
    required TileLayer options,
  }) =>
      _tiles.getSync(DatabaseTools.hash(getTileUrl(coords, options))) != null;

  /// Check whether a specified tile is cached in the current store asynchronously
  Future<bool> checkTileCachedAsync({
    required Coords<num> coords,
    required TileLayer options,
  }) async =>
      await _tiles.get(DatabaseTools.hash(getTileUrl(coords, options))) != null;
}
