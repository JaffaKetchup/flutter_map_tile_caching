// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Specialised [TileProvider] that uses a specialised [ImageProvider] to connect
/// to FMTC internals and enable advanced caching/retrieval logic
///
/// To use a single store, use [FMTCStore.getTileProvider].
///
/// To use multiple stores, use the [FMTCTileProvider.multipleStores]
/// constructor. See documentation on [storeNames] and [otherStoresStrategy]
/// for information on usage.
///
/// To use all stores, use the [FMTCTileProvider.allStores] constructor. See
/// documentation on [otherStoresStrategy] for information on usage.
///
/// An "FMTC" identifying mark is injected into the "User-Agent" header generated
/// by flutter_map, except if specified in the constructor. For technical
/// details, see [_CustomUserAgentCompatMap].
///
/// Can be constructed alternatively with [FMTCStore.getTileProvider] to
/// support a single store.
class FMTCTileProvider extends TileProvider {
  /// See [FMTCTileProvider] for information
  FMTCTileProvider.multipleStores({
    required this.storeNames,
    this.otherStoresStrategy,
    this.loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    this.useOtherStoresAsFallbackOnly = false,
    this.recordHitsAndMisses = true,
    this.cachedValidDuration = Duration.zero,
    UrlTransformer? urlTransformer,
    this.errorHandler,
    this.tileLoadingInterceptor,
    Client? httpClient,
    @visibleForTesting this.fakeNetworkDisconnect = false,
    Map<String, String>? headers,
  })  : urlTransformer = (urlTransformer ?? (u) => u),
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        _wasClientAutomaticallyGenerated = httpClient == null,
        super(
          headers: (headers?.containsKey('User-Agent') ?? false)
              ? headers
              : _CustomUserAgentCompatMap(headers ?? {}),
        );

  /// See [FMTCTileProvider] for information
  FMTCTileProvider.allStores({
    required BrowseStoreStrategy allStoresStrategy,
    this.loadingStrategy = BrowseLoadingStrategy.cacheFirst,
    this.useOtherStoresAsFallbackOnly = false,
    this.recordHitsAndMisses = true,
    this.cachedValidDuration = Duration.zero,
    UrlTransformer? urlTransformer,
    this.errorHandler,
    this.tileLoadingInterceptor,
    Client? httpClient,
    @visibleForTesting this.fakeNetworkDisconnect = false,
    Map<String, String>? headers,
  })  : storeNames = const {},
        otherStoresStrategy = allStoresStrategy,
        urlTransformer = (urlTransformer ?? (u) => u),
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
        _wasClientAutomaticallyGenerated = httpClient == null,
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
  /// stores should be used. Stores included but with a `null` value will be
  /// exempt from [otherStoresStrategy].
  final Map<String, BrowseStoreStrategy?> storeNames;

  /// The behaviour of all other stores not specified in [storeNames]
  ///
  /// `null` means that all other stores will not be used.
  ///
  /// Setting a non-`null` value may negatively impact performance, because
  /// internal tile cache lookups will have less constraints.
  ///
  /// Also see [useOtherStoresAsFallbackOnly] for whether these unspecified
  /// stores should only be used as a last resort or in addition to the specified
  /// stores as normal.
  ///
  /// Stores specified in [storeNames] but associated with a `null` value will
  /// not not gain this behaviour.
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
  /// When tiles are retrieved from other stores, it is counted as a miss for the
  /// specified store(s).
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
  /// to and were present in [FMTCTileProvider.storeNames], when necessary.
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
  /// The input string is the tile's URL. The output string should be a unique
  /// string to that tile that will remain as stable as necessary if parts of the
  /// URL not directly related to the tile image change.
  ///
  /// For more information, see:
  /// <https://fmtc.jaffaketchup.dev/flutter_map-integration/url-transformer>.
  ///
  /// [urlTransformerOmitKeyValues] may be used as a transformer to omit entire
  /// key-value pairs from a URL where the key matches one of the specified keys.
  ///
  /// > [!IMPORTANT]
  /// > The callback will be passed to a different isolate: therefore, avoid
  /// > using any external state that may not be properly captured or cannot be
  /// > copied to an isolate spawned with [Isolate.spawn] (see [SendPort.send]).
  ///
  /// _Internally, the storage-suitable UID is usually referred to as the tile
  /// URL (with distinction inferred)._
  ///
  /// By default, the output string is the input string - that is, the
  /// storage-suitable UID is the tile's real URL.
  final UrlTransformer urlTransformer;

  /// A custom callback that will be called when an [FMTCBrowsingError] is thrown
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
  /// If specified, then it will not be closed automatically on [dispose]al.
  /// When closing manually, ensure no requests are currently underway, else
  /// they will throw [ClientException]s.
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

  /// {@template fmtc.tileProvider.getBytes}
  /// Use FMTC's caching logic to get the bytes of the specific tile (at
  /// [coords]) with the specified [TileLayer] options and [FMTCTileProvider]
  /// provider
  ///
  /// Used internally by [_FMTCImageProvider.loadImage]. `loadImage` provides
  /// a decoding wrapper, but is only suitable for codecs Flutter can render.
  ///
  /// Therefore, this method does not make any assumptions about the format
  /// of the bytes, and it is up to the user to decode/render appropriately.
  /// For example, this could be incorporated into another [ImageProvider] (via
  /// a [TileProvider]) to integrate FMTC caching for vector tiles.
  ///
  /// ---
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
  /// the cache, which could cause further issues at a later point. However, this
  /// may be set `false` intentionally, for example to allow for vector tiles
  /// to be stored. If this is `true`, and the image is invalid, an
  /// [FMTCBrowsingError] with sub-category
  /// [FMTCBrowsingErrorType.invalidImageData] will be thrown - if `false`, then
  /// FMTC will not throw an error, but Flutter will if the bytes are attempted
  /// to be decoded (now or at a later time).
  /// {@endtemplate}
  Future<Uint8List> getBytes({
    required TileCoordinates coords,
    required TileLayer options,
    Object? key,
    void Function()? startedLoading,
    void Function()? finishedLoadingBytes,
    bool requireValidImage = false,
  }) =>
      _FMTCImageProvider.getBytes(
        coords: coords,
        options: options,
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
  }) =>
      FMTCBackendAccess.internal.tileExists(
        storeNames: _getSpecifiedStoresOrNull(),
        url: urlTransformer(getTileUrl(coords, options)),
      );

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

  /// If [storeNames] contains `null`, returns `null`, otherwise returns all
  /// non-null names (which cannot be empty)
  List<String>? _getSpecifiedStoresOrNull() =>
      otherStoresStrategy != null ? null : storeNames.keys.toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProvider &&
          mapEquals(other.storeNames, storeNames) &&
          other.otherStoresStrategy == otherStoresStrategy &&
          other.loadingStrategy == loadingStrategy &&
          other.useOtherStoresAsFallbackOnly == useOtherStoresAsFallbackOnly &&
          other.recordHitsAndMisses == recordHitsAndMisses &&
          other.cachedValidDuration == cachedValidDuration &&
          other.urlTransformer == urlTransformer &&
          other.errorHandler == errorHandler &&
          other.tileLoadingInterceptor == tileLoadingInterceptor &&
          other.httpClient == httpClient &&
          other.headers == headers);

  @override
  int get hashCode => Object.hash(
        storeNames,
        otherStoresStrategy,
        loadingStrategy,
        useOtherStoresAsFallbackOnly,
        recordHitsAndMisses,
        cachedValidDuration,
        urlTransformer,
        errorHandler,
        tileLoadingInterceptor,
        httpClient,
        headers,
      );
}
