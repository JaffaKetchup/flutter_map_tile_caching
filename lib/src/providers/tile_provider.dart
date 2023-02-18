// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// FMTC's custom [TileProvider] for use in a [TileLayer]
///
/// Create from the store directory chain, eg. [StoreDirectory.getTileProvider].
class FMTCTileProvider extends TileProvider {
  /// The store directory attached to this provider
  final StoreDirectory storeDirectory;

  /// The tile provider settings to use
  ///
  /// Defaults to the one provided by [FMTCSettings] when initialising
  /// [FlutterMapTileCaching].
  final FMTCTileProviderSettings settings;

  /// Used internally for browsing-caused tile requests
  final HttpClient httpClient;

  FMTCTileProvider._({
    required this.storeDirectory,
    required FMTCTileProviderSettings? settings,
    Map<String, String> headers = const {},
    HttpClient? httpClient,
  })  : settings =
            settings ?? FMTC.instance.settings.defaultTileProviderSettings,
        httpClient = httpClient ?? HttpClient()
          ..userAgent = null,
        super(
          headers: {
            ...headers,
            'User-Agent': headers['User-Agent'] == null
                ? 'flutter_map_tile_caching for flutter_map (unknown)'
                : 'flutter_map_tile_caching for ${headers['User-Agent']}',
          },
        );

  /// Closes the open [HttpClient] - this will make the provider unable to
  /// perform network requests
  @override
  void dispose() {
    httpClient.close();
    super.dispose();
  }

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to
  /// cache for later (dependent on the [CacheBehavior])
  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) =>
      FMTCImageProvider(
        provider: this,
        options: options,
        coords: coords,
      );

  IsarCollection<DbTile> get _tiles =>
      FMTCRegistry.instance(storeDirectory.storeName).tiles;

  /// Check whether a specified tile is cached in the current store synchronously
  bool checkTileCached({
    required Coords<num> coords,
    required TileLayer options,
  }) =>
      _tiles.getSync(DatabaseTools.hash(getTileUrl(coords, options))) != null;

  /// Check whether a specified tile is cached in the current store
  /// asynchronously
  Future<bool> checkTileCachedAsync({
    required Coords<num> coords,
    required TileLayer options,
  }) async =>
      await _tiles.get(DatabaseTools.hash(getTileUrl(coords, options))) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProvider &&
          other.runtimeType == runtimeType &&
          other.httpClient == httpClient &&
          other.settings == settings &&
          other.storeDirectory == storeDirectory &&
          other.headers == headers);

  @override
  int get hashCode => Object.hashAllUnordered([
        httpClient.hashCode,
        settings.hashCode,
        storeDirectory.hashCode,
        headers.hashCode,
      ]);
}
