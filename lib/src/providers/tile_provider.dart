// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Specialised [TileProvider] that uses a specialised [ImageProvider] to connect
/// to FMTC internals and enable advanced caching/retrieval logic
///
/// An "FMTC" identifying mark is injected into the "User-Agent" header generated
/// by flutter_map, except if specified in the constructor. For technical
/// details, see [_CustomUserAgentCompatMap].
class FMTCTileProvider extends TileProvider {
  /// Create a specialised [TileProvider] that uses a specialised [ImageProvider]
  /// to connect to FMTC internals and enable advanced caching/retrieval logic
  ///
  /// Supports multiple stores, by specifying each name in [storeNames]. If an
  /// empty list is specified, tiles will be fetched from all stores, but no
  /// tiles will be written to any stores. For more information, see
  /// [storeNames].
  /// Can be constructed alternatively with [FMTCStore.getTileProvider] to
  /// support a single store.
  ///
  /// See other documentation for more information.
  FMTCTileProvider({
    required this.storeNames,
    FMTCTileProviderSettings? settings,
    Map<String, String>? headers,
    http.Client? httpClient,
  })  : settings = settings ?? FMTCTileProviderSettings.instance,
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        super(
          headers: (headers?.containsKey('User-Agent') ?? false)
              ? headers
              : _CustomUserAgentCompatMap(headers ?? {}),
        );

  /// Create a specialised [TileProvider] that uses a specialised [ImageProvider]
  /// to connect to FMTC internals and enable advanced caching/retrieval logic
  ///
  /// Redirects to [FMTCTileProvider] constructor, but supports [FMTCStore]
  /// instead of [String].
  FMTCTileProvider.fromStores({
    required List<FMTCStore> stores,
    FMTCTileProviderSettings? settings,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) : this(
          storeNames: stores.map((s) => s.storeName).toList(),
          settings: settings,
          headers: headers,
          httpClient: httpClient,
        );

  /// The store names from which to fetch tiles and update tiles
  ///
  /// If empty, tiles will be fetched from all stores, but no tiles will be
  /// written to any stores (regardless of [FMTCTileProviderSettings.behavior]).
  /// This may introduce notable performance reductions, especially if failures
  /// occur often or the root is particularly large, as the tile queries will
  /// have unbounded constraints.
  ///
  /// See also:
  ///  - [FMTCTileProviderSettings.fallbackToAlternativeStore], which has a
  ///    similar behaviour, but only does so when the tile cannot be found in
  ///    these stores
  final List<String>? storeNames;

  /// The tile provider settings to use
  ///
  /// Defaults to the ambient [FMTCTileProviderSettings.instance].
  final FMTCTileProviderSettings settings;

  /// [http.Client] (such as a [IOClient]) used to make all network requests
  ///
  /// Do not close manually.
  ///
  /// Defaults to a standard [IOClient]/[HttpClient].
  final http.Client httpClient;

  /// Each [Completer] is completed once the corresponding tile has finished
  /// loading
  ///
  /// Used to avoid disposing of [httpClient] whilst HTTP requests are still
  /// underway.
  ///
  /// Does not include tiles loaded from session cache.
  final _tilesInProgress = HashMap<TileCoordinates, Completer<void>>.identity();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _FMTCImageProvider(
        provider: this,
        options: options,
        coords: coordinates,
        startedLoading: () => _tilesInProgress[coordinates] = Completer(),
        finishedLoadingBytes: () {
          _tilesInProgress[coordinates]?.complete();
          _tilesInProgress.remove(coordinates);
        },
      );

  @override
  Future<void> dispose() async {
    if (_tilesInProgress.isNotEmpty) {
      await Future.wait(_tilesInProgress.values.map((c) => c.future));
    }
    httpClient.close();
    super.dispose();
  }

  /// {@macro fmtc.imageProvider.getBytes}
  Future<Uint8List> getBytes({
    required TileCoordinates coordinates,
    required TileLayer options,
    StreamController<ImageChunkEvent>? chunkEvents,
    bool requireValidImage = true,
  }) =>
      _FMTCImageProvider.getBytes(
        provider: this,
        options: options,
        coords: coordinates,
        chunkEvents: chunkEvents,
        requireValidImage: requireValidImage,
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
      FMTCBackendAccess.internal.tileExists(
        storeNames: storeNames,
        url: obscureQueryParams(
          url: getTileUrl(coords, options),
          obscuredQueryParams: settings.obscuredQueryParams,
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProvider &&
          other.storeNames == storeNames &&
          other.headers == headers &&
          other.settings == settings &&
          other.httpClient == httpClient);

  @override
  int get hashCode => Object.hash(storeNames, settings, headers, httpClient);
}

/// Custom override of [Map] that only overrides the [MapView.putIfAbsent]
/// method, to enable injection of an identifying mark ("FMTC")
class _CustomUserAgentCompatMap extends MapView<String, String> {
  const _CustomUserAgentCompatMap(super.map);

  /// Modified implementation of [MapView.putIfAbsent], that overrides behaviour
  /// only when [key] is "User-Agent"
  ///
  /// flutter_map's [TileLayer] constructor calls this method after the
  /// [TileLayer.tileProvider] has been constructed to customize the
  /// "User-Agent" header with `TileLayer.userAgentPackageName`.
  /// This method intercepts any call with [key] equal to "User-Agent" and
  /// replacement value that matches the expected format, and adds an "FMTC"
  /// identifying mark.
  ///
  /// The identifying mark is injected to seperate traffic sent via FMTC from
  /// standard flutter_map traffic, as it significantly changes the behaviour of
  /// tile retrieval, and could generate more traffic.
  @override
  String putIfAbsent(String key, String Function() ifAbsent) {
    if (key != 'User-Agent') return super.putIfAbsent(key, ifAbsent);

    final replacementValue = ifAbsent();
    if (!RegExp(r'flutter_map \(.+\)').hasMatch(replacementValue)) {
      return super.putIfAbsent(key, ifAbsent);
    }
    return this[key] = replacementValue.replaceRange(11, 12, ' + FMTC ');
  }
}
