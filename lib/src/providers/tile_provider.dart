// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// FMTC's custom [TileProvider] for use in a [TileLayer]
///
/// Create from the store directory chain, eg. [FMTCStore.getTileProvider].
class FMTCTileProvider extends TileProvider {
  FMTCTileProvider._(
    this._store, {
    required FMTCTileProviderSettings? settings,
    required Map<String, String> headers,
    required http.Client? httpClient,
  })  : settings = settings ?? FMTCTileProviderSettings.instance,
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        super(
          headers: {
            ...headers,
            'User-Agent': headers['User-Agent'] == null
                ? 'flutter_map_tile_caching for flutter_map (unknown)'
                : 'flutter_map_tile_caching for ${headers['User-Agent']}',
          },
        );

  /// The store directory attached to this provider
  final FMTCStore _store;

  /// The tile provider settings to use
  final FMTCTileProviderSettings settings;

  /// [http.Client] (such as a [IOClient]) used to make all network requests
  ///
  /// Defaults to a standard [IOClient]/[HttpClient] for HTTP/1.1 servers.
  final http.Client httpClient;

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
        storeName: _store.storeName,
        provider: this,
        options: options,
        coords: coords,
      );

  /// Check whether a specified tile is cached in the current store
  @Deprecated('''
Migrate to `checkTileCached`.

Synchronous operations have been removed throughout FMTC v9, therefore the
distinction between sync and async operations has been removed. This deprecated
member will be removed in a future version.''')
  Future<bool> checkTileCachedAsync({
    required TileCoordinates coords,
    required TileLayer options,
  }) =>
      checkTileCached(coords: coords, options: options);

  /// Check whether a specified tile is cached in the current store
  Future<bool> checkTileCached({
    required TileCoordinates coords,
    required TileLayer options,
  }) =>
      FMTCBackendAccess.internal.tileExistsInStore(
        storeName: _store.storeName,
        url: obscureQueryParams(
          url: getTileUrl(coords, options),
          obscuredQueryParams: settings.obscuredQueryParams,
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProvider &&
          other._store == _store &&
          other.headers == headers &&
          other.settings == settings &&
          other.httpClient == httpClient);

  @override
  int get hashCode => Object.hash(_store, settings, headers, httpClient);
}
