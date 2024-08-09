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
    http.Client? httpClient,
    Map<String, String>? headers,
  })  : assert(storeNames.isNotEmpty, '`storeNames` cannot be empty'),
        urlTransformer = (urlTransformer ?? (u) => u),
        httpClient = httpClient ?? IOClient(HttpClient()..userAgent = null),
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
    http.Client? httpClient,
    Map<String, String>? headers,
  })  : storeNames = const {},
        otherStoresStrategy = allStoresStrategy,
        urlTransformer = (urlTransformer ?? (u) => u),
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
  /// stores should be used.
  final Map<String, BrowseStoreStrategy> storeNames;

  /// The behaviour of all other stores not specified in [storeNames]
  ///
  /// `null` means that all other stores will not be used.
  ///
  /// Setting a non-`null` value may reduce performance, as internal queries
  /// will have fewer constraints and therefore be less efficient.
  ///
  /// Also see [useOtherStoresAsFallbackOnly] for whether these unspecified
  /// stores should only be used as a last resort or in addition to the specified
  /// stores as normal.
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
  /// This may introduce notable performance reductions, especially if failures
  /// occur often or the root is particularly large, as an extra lookup with
  /// unbounded constraints is required for each tile.
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
  /// To store and retrieve tiles, FMTC uses a tile's storage-suitable UID.
  /// When a tile is stored, the tile URL is transformed before storage. When a
  /// tile is retrieved from the cache, the tile URL is transformed before
  /// retrieval.
  ///
  /// A storage-suitable UID is usually the tile's own real URL - although it may
  /// not necessarily be. The tile URL is guaranteed to refer only to that tile
  /// from that server (unless the server backend changes).
  ///
  /// However, some parts of the tile URL should not be stored. For example,
  /// an API key transmitted as part of the query parameters should not be
  /// stored - and is not storage-suitable. This is because, if the API key
  /// changes, the cached tile will still use the old UID containing the old API
  /// key, and thus the tile will never be retrieved from storage, even if the
  /// image is the same.
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
  final _tilesInProgress = HashMap<TileCoordinates, Completer<void>>();

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
    required TileCoordinates coords,
    required TileLayer options,
    Object? key,
    StreamController<ImageChunkEvent>? chunkEvents,
    void Function()? startedLoading,
    void Function()? finishedLoadingBytes,
    bool requireValidImage = false,
  }) =>
      _FMTCImageProvider.getBytes(
        coords: coords,
        options: options,
        provider: this,
        key: key,
        chunkEvents: chunkEvents,
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

  /// Removes specified key-value pairs from the specified [url]
  ///
  /// Both the key itself and its associated value, for each of [keys], will be
  /// omitted.
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
