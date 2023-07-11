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

  /// [http.Client] (such as a [IOClient]) used to make all network requests
  ///
  /// Defaults to a standard [IOClient]/[HttpClient] for HTTP/1.1 servers.
  final http.Client httpClient;

  FMTCTileProvider._({
    required this.storeDirectory,
    required FMTCTileProviderSettings? settings,
    Map<String, String> headers = const {},
    http.Client? httpClient,
  })  : settings =
            settings ?? FMTC.instance.settings.defaultTileProviderSettings,
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        super(
          headers: {
            ...headers,
            'User-Agent': headers['User-Agent'] == null
                ? 'flutter_map_tile_caching for flutter_map (unknown)'
                : 'flutter_map_tile_caching for ${headers['User-Agent']}',
          },
        );

  /// Closes the open [httpClient] - this will make the provider unable to
  /// perform network requests
  @override
  void dispose() {
    httpClient.close();
    super.dispose();
  }

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to
  /// cache for later (dependent on the [CacheBehavior])
  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) =>
      FMTCImageProvider(
        provider: this,
        options: options,
        coords: coords,
        directory: FMTC.instance.rootDirectory.directory.absolute.path,
      );

  /// Check whether a specified tile is cached in the current store synchronously
  bool checkTileCached({
    required TileCoordinates coords,
    required TileLayer options,
  }) =>
      FMTCRegistry.instance(storeDirectory.storeName).tiles.getSync(
            DatabaseTools.hash(
              obscureQueryParams(
                url: getTileUrl(coords, options),
                obscuredQueryParams: settings.obscuredQueryParams,
              ),
            ),
          ) !=
      null;

  /// Check whether a specified tile is cached in the current store
  /// asynchronously
  Future<bool> checkTileCachedAsync({
    required TileCoordinates coords,
    required TileLayer options,
  }) async =>
      await FMTCRegistry.instance(storeDirectory.storeName).tiles.get(
            DatabaseTools.hash(
              obscureQueryParams(
                url: getTileUrl(coords, options),
                obscuredQueryParams: settings.obscuredQueryParams,
              ),
            ),
          ) !=
      null;

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
  int get hashCode =>
      Object.hash(httpClient, settings, storeDirectory, headers);
}
