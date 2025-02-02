// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Specialised [TileProvider] that uses a specialised [ImageProvider] to
/// connect to FMTC internals and enable advanced caching/retrieval logic
///
/// To use a single or multiple stores, use the [FMTCTileProvider.new]
/// constructor. See documentation on [stores] and [otherStoresStrategy]
/// for information on usage.
///
/// To use all stores, use the [FMTCTileProvider.allStores] constructor. See
/// documentation on [otherStoresStrategy] for information on usage.
///
/// {@template fmtc.fmtcTileProvider.constructionTip}
/// > [!TIP]
/// >
/// > **Minimize reconstructions of this provider by constructing it outside of
/// > the `build` method of a widget wherever possible.**
/// >
/// > If this is not possible, because one or more properties depend on
/// > inherited data (ie. via an `InheritedWidget`, `Provider`, etc.), define
/// > and construct as many properties as possible outside of the `build`
/// > method.
/// >
/// > * Manually constructing and initialising an [httpClient] once is much
/// > cheaper than the [FMTCTileProvider]'s constructors doing it automatically
/// > on every construction (every rebuild), and allows a single connection to
/// > the server to be maintained, massively improving tile loading speeds. Also
/// > see [httpClient]'s documentation.
/// >
/// > * Properties that use objects without a useful equality and hash code
/// > should always be defined once outside of the build method so that their
/// > identity (by [identical]) is not changed - for example, [httpClient],
/// > [tileLoadingInterceptor], [errorHandler], and [urlTransformer].
/// > All properties comprise part of the [hashCode] & [operator ==], which are
/// > used to form the Flutter session [ImageCache] key in the internal image
/// > provider (alongside the tile coordinates). This key should not change for
/// > a tile unless the configuration is actually changed meaningfully, as this
/// > will disrupt the session cache, and mean tiles may need to be fetched
/// > unnecessarily.
/// >
/// > See the online documentation for an example of the recommended usage.
/// {@endtemplate}
@immutable
class FMTCTileProvider extends TileProvider {
  /// Create an [FMTCTileProvider] that interacts with a subset of all available
  /// stores
  ///
  /// See [stores] & [otherStoresStrategy] for information.
  ///
  /// {@macro fmtc.fmtcTileProvider.constructionTip}
  FMTCTileProvider({
    required this.stores,
    this.otherStoresStrategy,
    this.loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    this.useOtherStoresAsFallbackOnly = false,
    this.recordHitsAndMisses = true,
    this.cachedValidDuration = Duration.zero,
    this.urlTransformer,
    this.errorHandler,
    this.tileLoadingInterceptor,
    Client? httpClient,
    @visibleForTesting this.fakeNetworkDisconnect = false,
    Map<String, String>? headers,
  })  : _wasClientAutomaticallyGenerated = httpClient == null,
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        super(
          headers: (headers?.containsKey('User-Agent') ?? false)
              ? headers
              : _CustomUserAgentCompatMap(headers ?? {}),
        );

  /// Create an [FMTCTileProvider] that interacts with all available stores,
  /// using one [BrowseStoreStrategy] efficiently
  ///
  /// {@macro fmtc.fmtcTileProvider.constructionTip}
  FMTCTileProvider.allStores({
    required BrowseStoreStrategy allStoresStrategy,
    this.loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    this.recordHitsAndMisses = true,
    this.cachedValidDuration = Duration.zero,
    this.urlTransformer,
    this.errorHandler,
    this.tileLoadingInterceptor,
    Client? httpClient,
    @visibleForTesting this.fakeNetworkDisconnect = false,
    Map<String, String>? headers,
  })  : stores = const {},
        otherStoresStrategy = allStoresStrategy,
        useOtherStoresAsFallbackOnly = false,
        _wasClientAutomaticallyGenerated = httpClient == null,
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        super(
          headers: (headers?.containsKey('User-Agent') ?? false)
              ? headers
              : _CustomUserAgentCompatMap(headers ?? {}),
        );

  /// The store names from which to (possibly) read/update/create tiles from/in
  ///
  /// Keys represent store names, and the associated [BrowseStoreStrategy]
  /// represents how that store should be used.
  ///
  /// Stores not included will not be used by default. However,
  /// [otherStoresStrategy] determines whether & how all other unspecified
  /// stores should be used. Stores included in this mapping but with a `null`
  /// value will be exempted from [otherStoresStrategy] (ie. unused).
  ///
  /// All specified store names should correspond to existing stores.
  /// Non-existant stores may cause unexpected read behaviour and will throw a
  /// [StoreNotExists] error if a tile is attempted to be written to it.
  final Map<String, BrowseStoreStrategy?> stores;

  /// The behaviour of all other stores not specified in [stores]
  ///
  /// `null` means that all other stores will not be used.
  ///
  /// Setting a non-`null` value may negatively impact performance, because
  /// internal tile cache lookups will have less constraints.
  ///
  /// Also see [useOtherStoresAsFallbackOnly] for whether these unspecified
  /// stores should only be used as a last resort or in addition to the
  /// specified stores as normal.
  ///
  /// Stores specified in [stores] but associated with a `null` value will not
  /// gain this behaviour.
  final BrowseStoreStrategy? otherStoresStrategy;

  /// Determines whether the network or cache is preferred during browse
  /// caching, and how to fallback
  ///
  /// Defaults to [BrowseLoadingStrategy.cacheFirst].
  final BrowseLoadingStrategy loadingStrategy;

  /// Whether to only use tiles retrieved by
  /// [FMTCTileProvider.otherStoresStrategy] after all specified stores have
  /// been exhausted (where the tile was not present)
  ///
  /// When tiles are retrieved from other stores, it is counted as a miss for
  /// the specified store(s).
  ///
  /// Note that an attempt is *always* made to read the tile from the cache,
  /// regardless of whether the tile is then actually retrieved from the cache
  /// or the network is then used (successfully).
  ///
  /// For example, if a specified store does not contain the tile, and an
  /// unspecified store does contain the tile:
  ///  * if this is `false`, then the tile will be retrieved and used from the
  /// unspecified store
  ///  * if this is `true`, then the tile will be retrieved (see note above),
  /// but not used unless the network request fails
  ///
  /// Defaults to `false`.
  final bool useOtherStoresAsFallbackOnly;

  /// Whether to record the [StoreStats.hits] and [StoreStats.misses] statistics
  ///
  /// When enabled, hits will be recorded for all stores that the tile belonged
  /// to and were present in [FMTCTileProvider.stores], when necessary.
  /// Misses will be recorded for all stores specified in the tile provided,
  /// where necessary
  ///
  /// Disable to improve performance and/or if these statistics are never used.
  ///
  /// Defaults to `true`.
  final bool recordHitsAndMisses;

  /// The duration for which a tile does not require updating when cached, after
  /// which it is marked as expired and updated at the next possible
  /// opportunity
  ///
  /// Set to [Duration.zero] to never expire a tile (default).
  final Duration cachedValidDuration;

  /// Method used to create a tile's storage-suitable UID from it's real URL
  ///
  /// For more information, check the
  /// [online documentation](https://fmtc.jaffaketchup.dev/usage/integrating-with-a-map#ensure-tiles-are-resilient-to-url-changes).
  ///
  /// The input string is the tile's URL. The output string should be a unique
  /// string to that tile that will remain as stable as necessary if parts of
  /// the URL not directly related to the tile image change.
  ///
  /// [urlTransformerOmitKeyValues] may be used as a transformer to omit entire
  /// key-value pairs from a URL where the key matches one of the specified
  /// keys.
  ///
  /// By default, the output string is the input string - that is, the
  /// storage-suitable UID is the tile's real URL.
  final UrlTransformer? urlTransformer;

  /// A custom callback that will be called when an [FMTCBrowsingError] is
  /// thrown
  ///
  /// If no value is returned, the error will be (re)thrown as normal. However,
  /// if a [Uint8List], that will be displayed instead (decoded as an image),
  /// and no error will be thrown.
  final BrowsingExceptionHandler? errorHandler;

  /// Allows tracking (eg. for debugging and logging) of the internal tile
  /// loading mechanisms
  ///
  /// For example, this could be used to debug why tiles aren't loading as
  /// expected (perhaps in combination with [TileLayer.tileBuilder] &
  /// [ValueListenableBuilder] as in the example app), or to perform more
  /// advanced monitoring and logging than the hit & miss statistics provide.
  ///
  /// ---
  ///
  /// To use, first initialise a [ValueNotifier], like so, then pass it to this
  /// parameter:
  ///
  /// ```dart
  /// // outside of the `build` method
  /// final tileLoadingInterceptor =
  ///   ValueNotifier<TileLoadingInterceptorMap>({}); // Do not use `const {}`
  /// ```
  ///
  /// This notifier will be notified, and the `value` updated, every time a tile
  /// completes loading (successfully or unsuccessfully). The `value` maps
  /// [TileCoordinates]s to [TileLoadingInterceptorResult]s.
  final ValueNotifier<TileLoadingInterceptorMap>? tileLoadingInterceptor;

  /// [Client] (such as a [IOClient]) used to make all network requests
  ///
  /// If this provider could be rebuild frequently (ie. it is constructed in a
  /// build method), a client should always be defined manually outside of the
  /// build method and passed into the constructor. See the documentation tip on
  /// [FMTCTileProvider] for more information. For example (this is also the
  /// same client as created automatically by the constructor if no argument
  /// is passed):
  ///
  /// ```dart
  /// // `StatefulWidget` class definition
  ///
  /// class _...State extends State<...> {
  ///   late final _httpClient = IOClient(HttpClient()..userAgent = null);
  ///   // followed by other state contents, such as `build`
  /// }
  /// ```
  ///
  /// Any specified user agent defined on the client will be overriden.
  /// If a "User-Agent" header is specified in [headers] it will be used.
  /// Otherwise, the default flutter_map user agent logic is used, followed by
  /// an injected "FMTC" identifying mark (see [_CustomUserAgentCompatMap]).
  ///
  /// If a client is passed in, it should not be closed manually unless certain
  /// that all tile requests have finished, else they will throw
  /// [ClientException]s. If the constructor automatically creates a client (
  /// because one was not passed as an argument), it will be closed safely
  /// automatically on [dispose]al.
  ///
  /// Defaults to a standard [IOClient]/[HttpClient].
  final Client httpClient;

  /// Whether to fake a network disconnect for the purpose of testing
  ///
  /// When `true`, prevents a network request and instead throws a
  /// [SocketException].
  ///
  /// Defaults to `false`.
  @visibleForTesting
  final bool fakeNetworkDisconnect;

  /// Each [Completer] is completed once the corresponding tile has finished
  /// loading
  ///
  /// Used to avoid disposing of [httpClient] whilst HTTP requests are still
  /// underway.
  ///
  /// Does not include tiles loaded from session cache.
  final _tilesInProgress = HashMap<TileCoordinates, Completer<void>>();

  final bool _wasClientAutomaticallyGenerated;

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
    if (_wasClientAutomaticallyGenerated) {
      if (_tilesInProgress.isNotEmpty) {
        await Future.wait(_tilesInProgress.values.map((c) => c.future));
      }
      httpClient.close();
    }
    super.dispose();
  }

  /// {@template fmtc.tileProvider.provideTile}
  /// Use FMTC's caching logic to get the bytes of the tile at [networkUrl]
  ///
  /// > [!IMPORTANT]
  /// > Note that this will actuate the cache writing mechanism as if a normal
  /// > tile browse request was made - ie. the bytes returned may be written to
  /// > the cache.
  ///
  /// Used internally by [_FMTCImageProvider.loadImage]. `loadImage` provides a
  /// decoding wrapper to display the bytes as an image, but is only suitable
  /// for codecs Flutter can render.
  ///
  /// > [!TIP]
  /// > This method does not make any assumptions about theformat of the bytes,
  /// > and it is up to the user to decode/render appropriately. For example, this
  /// > could be incorporated into another [ImageProvider] (via a
  /// > [TileProvider]) to integrate FMTC caching for vector tiles.
  ///
  /// ---
  ///
  /// [coords] is required to enable functioning of
  /// [FMTCTileProvider.tileLoadingInterceptor]. If the tile loading interceptor
  /// is not in use, providing coordinates is not necessary.
  ///
  /// [key] is used to control the [ImageCache], and should be set when in a
  /// context where [ImageProvider.obtainKey] is available.
  ///
  /// [startedLoading] & [finishedLoadingBytes] are used to indicate to
  /// flutter_map when it is safe to dispose a [TileProvider], and should be set
  /// when used inside a [TileProvider]'s context (such as directly or within
  /// a dedicated [ImageProvider]).
  ///
  /// [requireValidImage] is `false` by default, but should be `true` when
  /// only Flutter decodable data is being used (ie. most raster tiles) (and is
  /// set `true` when used by `loadImage` internally). This provides an extra
  /// layer of protection by preventing invalid data from being stored inside
  /// the cache, which could cause further issues at a later point. However,
  /// this may be set `false` intentionally, for example to allow for vector
  /// tiles to be stored. If this is `true`, and the image is invalid, an
  /// [FMTCBrowsingError] with sub-category
  /// [FMTCBrowsingErrorType.invalidImageData] will be thrown - if `false`, then
  /// FMTC will not throw an error, but Flutter will if the bytes are attempted
  /// to be decoded (now or at a later time).
  /// {@endtemplate}
  Future<Uint8List> provideTile({
    required String networkUrl,
    TileCoordinates? coords,
    Object? key,
    void Function()? startedLoading,
    void Function()? finishedLoadingBytes,
    bool requireValidImage = false,
  }) =>
      _FMTCImageProvider.provideTile(
        coords: coords,
        networkUrl: networkUrl,
        provider: this,
        key: key,
        startedLoading: startedLoading,
        finishedLoadingBytes: finishedLoadingBytes,
        requireValidImage: requireValidImage,
      );

  /// Check whether a specified tile is cached in any of the current stores
  ///
  /// If [otherStoresStrategy] is not `null`, then the check is for if the
  /// tile has been cached in any store.
  Future<bool> isTileCached({
    required TileCoordinates coords,
    required TileLayer options,
  }) {
    final networkUrl = getTileUrl(coords, options);
    return FMTCBackendAccess.internal.tileExists(
      storeNames: _compileReadableStores(),
      url: urlTransformer?.call(networkUrl) ?? networkUrl,
    );
  }

  /// Removes key-value pairs from the specified [url], given only the [keys]
  ///
  /// [link] connects a key to its value (defaults to '='). [delimiter]
  /// seperates two different key value pairs (defaults to '&').
  ///
  /// For example, the [url] 'abc=123&xyz=987' with [keys] only containing 'abc'
  /// would become '&xyz=987'. In this case, if these were query parameters, it
  /// is assumed the server will be able to handle a missing first query
  /// parameter.
  ///
  /// Matching and removal is performed by a regular expression. Does not mutate
  /// input [url]. [link] and [delimiter] are escaped (using [RegExp.escape])
  /// before they are used within the regular expression.
  ///
  /// This is not designed to be a security mechanism, and should not be relied
  /// upon as such.
  ///
  /// See [urlTransformer] for more information.
  static String urlTransformerOmitKeyValues({
    required String url,
    required Iterable<String> keys,
    String link = '=',
    String delimiter = '&',
  }) {
    var mutableUrl = url;
    for (final key in keys) {
      mutableUrl = mutableUrl.replaceAll(
        RegExp(
          '${RegExp.escape(key)}${RegExp.escape(link)}'
          '[^${RegExp.escape(delimiter)}]*',
        ),
        '',
      );
    }
    return mutableUrl;
  }

  /// Compile the [FMTCTileProvider.stores] &
  /// [FMTCTileProvider.otherStoresStrategy] into a format which can be resolved
  /// by the backend once all available stores are known
  ({List<String> storeNames, bool includeOrExclude}) _compileReadableStores() {
    final excludeOrInclude = otherStoresStrategy != null;
    final storeNames = (excludeOrInclude
            ? stores.entries.where((e) => e.value == null)
            : stores.entries.where((e) => e.value != null))
        .map((e) => e.key)
        .toList(growable: false);
    return (storeNames: storeNames, includeOrExclude: !excludeOrInclude);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProvider &&
          other.otherStoresStrategy == otherStoresStrategy &&
          other.loadingStrategy == loadingStrategy &&
          other.useOtherStoresAsFallbackOnly == useOtherStoresAsFallbackOnly &&
          other.recordHitsAndMisses == recordHitsAndMisses &&
          other.cachedValidDuration == cachedValidDuration &&
          other.urlTransformer == urlTransformer &&
          other.errorHandler == errorHandler &&
          other.tileLoadingInterceptor == tileLoadingInterceptor &&
          other.httpClient == httpClient &&
          mapEquals(other.stores, stores) &&
          mapEquals(other.headers, headers));

  @override
  int get hashCode => Object.hashAllUnordered([
        otherStoresStrategy,
        loadingStrategy,
        useOtherStoresAsFallbackOnly,
        recordHitsAndMisses,
        cachedValidDuration,
        urlTransformer,
        errorHandler,
        tileLoadingInterceptor,
        httpClient,
        ...stores.entries.map((e) => (e.key, e.value)),
        ...headers.entries.map((e) => (e.key, e.value)),
      ]);
}
