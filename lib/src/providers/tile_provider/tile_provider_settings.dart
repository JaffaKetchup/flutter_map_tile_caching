// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Settings for an [FMTCTileProvider]
///
/// This class is a kind of singleton, which maintains a single instance, but
/// allows allows for a one-shot creation where necessary.
class FMTCTileProviderSettings {
  /// Create new settings for an [FMTCTileProvider], and set the [instance] (if
  /// [setInstance] is `true`, as default)
  ///
  /// To access the existing settings, if any, get [instance].
  factory FMTCTileProviderSettings({
    CacheBehavior behavior = CacheBehavior.cacheFirst,
    Duration cachedValidDuration = const Duration(days: 16),
    bool useUnspecifiedAsLastResort = false,
    bool trackHitsAndMisses = true,
    String Function(String)? urlTransformer,
    @Deprecated(
      '`obscuredQueryParams` has been deprecated in favour of `urlTransformer`, '
      'which provides more flexibility.\n'
      'To restore similar functioning, use '
      '`FMTCTileProviderSettings.urlTransformerOmitKeyValues`. Note that this '
      'will apply to the entire URL, not only the query part, which may have '
      'a different behaviour in some rare cases.\n'
      'This argument will be removed in a future version.',
    )
    List<String> obscuredQueryParams = const [],
    FMTCBrowsingErrorHandler? errorHandler,
    bool setInstance = true,
  }) {
    final settings = FMTCTileProviderSettings._(
      behavior: behavior,
      cachedValidDuration: cachedValidDuration,
      useOtherStoresAsFallbackOnly: useUnspecifiedAsLastResort,
      recordHitsAndMisses: trackHitsAndMisses,
      urlTransformer: urlTransformer ??
          (obscuredQueryParams.isNotEmpty
              ? (url) {
                  final components = url.split('?');
                  if (components.length == 1) return url;
                  return '${components[0]}?'
                      '${urlTransformerOmitKeyValues(
                    url: url,
                    keys: obscuredQueryParams,
                  )}';
                }
              : (e) => e),
      errorHandler: errorHandler,
    );

    if (setInstance) _instance = settings;
    return settings;
  }

  FMTCTileProviderSettings._({
    required this.behavior,
    required this.cachedValidDuration,
    required this.useOtherStoresAsFallbackOnly,
    required this.recordHitsAndMisses,
    required this.urlTransformer,
    required this.errorHandler,
  });

  /// Get an existing instance, if one has been constructed, or get the default
  /// intial configuration
  static FMTCTileProviderSettings get instance => _instance;
  static var _instance = FMTCTileProviderSettings();

  /// The behaviour to use when retrieving and writing tiles when browsing
  ///
  /// Defaults to [CacheBehavior.cacheFirst].
  final CacheBehavior behavior;

  /// Whether to only use tiles retrieved by
  /// [FMTCTileProvider.otherStoresBehavior] after all specified stores have
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

  /// Whether to keep track of the [StoreStats.hits] and [StoreStats.misses]
  /// statistics
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

  /// The duration until a tile expires and needs to be fetched again when
  /// browsing. Also called `validDuration`.
  ///
  /// Defaults to 16 days, set to [Duration.zero] to disable.
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
  /// [FMTCTileProviderSettings.urlTransformerOmitKeyValues] may be used as a
  /// transformer to omit entire key-value pairs from a URL where the key matches
  /// one of the specified keys.
  ///
  /// > [!IMPORTANT]
  /// > The callback should be **stateless** and **self-contained**. That is,
  /// > the callback should not depend on any other tile or other state that is
  /// > in memory only, and it should not use nor store any state externally or
  /// > from any other scope (with the exception of the argument). This callback
  /// > will be transferred to a seperate isolate when downloading, and therefore
  /// > these external dependencies may not work as expected, at all, or be in
  /// > the expected state.
  ///
  /// _Internally, the storage-suitable UID is usually referred to as the tile
  /// URL (with distinction inferred)._
  ///
  /// By default, the output string is the input string - that is, the
  /// storage-suitable UID is the tile's real URL.
  final String Function(String) urlTransformer;

  /// A custom callback that will be called when an [FMTCBrowsingError] is raised
  ///
  /// If no value is returned, the error will be (re)thrown as normal. However,
  /// if a [Uint8List], that will be displayed instead (decoded as an image),
  /// and no error will be thrown.
  final FMTCBrowsingErrorHandler? errorHandler;

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
  /// input [url].
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
      mutableUrl = mutableUrl.replaceAll(RegExp('$key$link[^$delimiter]*'), '');
    }
    return mutableUrl;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProviderSettings &&
          other.behavior == behavior &&
          other.cachedValidDuration == cachedValidDuration &&
          other.useOtherStoresAsFallbackOnly == useOtherStoresAsFallbackOnly &&
          other.recordHitsAndMisses == recordHitsAndMisses &&
          other.urlTransformer == other.urlTransformer &&
          other.errorHandler == errorHandler);

  @override
  int get hashCode => Object.hashAllUnordered([
        behavior,
        cachedValidDuration,
        useOtherStoresAsFallbackOnly,
        recordHitsAndMisses,
        urlTransformer,
        errorHandler,
      ]);
}

/// Callback type that takes an [FMTCBrowsingError] exception
typedef FMTCBrowsingErrorHandler = Uint8List? Function(
  FMTCBrowsingError exception,
);
