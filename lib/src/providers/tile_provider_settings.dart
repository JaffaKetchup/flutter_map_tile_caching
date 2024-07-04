// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Callback type that takes an [FMTCBrowsingError] exception
typedef FMTCBrowsingErrorHandler = ImmutableBuffer? Function(
  FMTCBrowsingError exception,
);

/// Alias of [CacheBehavior]
///
/// ... with the correct spelling :D
typedef CacheBehaviour = CacheBehavior;

/// Behaviours dictating how and when browse caching should occur
///
/// | `CacheBehavior`          | Preferred fetch method | Fallback fetch method |
/// |--------------------------|------------------------|-----------------------|
/// | `cacheOnly`              | Cache                  | None                  |
/// | `cacheFirst`             | Cache                  | Network               |
/// | `onlineFirst`            | Network                | Cache                 |
/// | *Standard Tile Provider* | *Network*              | *None*                |
enum CacheBehavior {
  /// Only fetch tiles from the local cache
  ///
  /// In this mode, [StoreReadWriteBehavior] is irrelevant.
  ///
  /// Throws [FMTCBrowsingErrorType.missingInCacheOnlyMode] if a tile is
  /// unavailable.
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheOnly,

  /// Fetch tiles from the cache, falling back to the network to fetch and
  /// create/update non-existent/expired tiles, dependent on the selected
  /// [StoreReadWriteBehavior]
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheFirst,

  /// Fetch and create/update non-existent/expired tiles from the network,
  /// falling back to the cache to fetch tiles, dependent on the selected
  /// [StoreReadWriteBehavior]
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  onlineFirst,
}

/// Alias of [StoreReadWriteBehavior]
///
/// ... with the correct spelling :D
typedef StoreReadWriteBehaviour = StoreReadWriteBehavior;

/// Determines the read/update/create tile behaviour of a store
enum StoreReadWriteBehavior {
  /// Only read tiles
  read,

  /// Read tiles, and also update existing tiles
  ///
  /// Unlike 'create', if (an older version of) a tile does not already exist in
  /// the store, it will not be written.
  readUpdate,

  /// Read, update, and create tiles
  ///
  /// See [readUpdate] for a definition of 'update'.
  readUpdateCreate,
}

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
    List<String> obscuredQueryParams = const [],
    FMTCBrowsingErrorHandler? errorHandler,
    bool setInstance = true,
  }) {
    final settings = FMTCTileProviderSettings._(
      behavior: behavior,
      cachedValidDuration: cachedValidDuration,
      useOtherStoresAsFallbackOnly: useUnspecifiedAsLastResort,
      recordHitsAndMisses: trackHitsAndMisses,
      obscuredQueryParams: obscuredQueryParams.map((e) => RegExp('$e=[^&]*')),
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
    required this.obscuredQueryParams,
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

  /// A list of regular expressions indicating key-value pairs to be remove from
  /// a URL's query parameter list
  ///
  /// If using this property, it is recommended to set it globally on
  /// initialisation with [FMTCTileProviderSettings], to ensure it gets applied
  /// throughout.
  ///
  /// Used by [obscureQueryParams] to apply to a URL.
  ///
  /// See the [online documentation](https://fmtc.jaffaketchup.dev/usage/integration#obscuring-query-parameters)
  /// for more information.
  final Iterable<RegExp> obscuredQueryParams;

  /// A custom callback that will be called when an [FMTCBrowsingError] is raised
  ///
  /// If no value is returned, the error will be (re)thrown as normal. However,
  /// if an [ImmutableBuffer] representing an image is returned, that will be
  /// displayed instead.
  final FMTCBrowsingErrorHandler? errorHandler;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProviderSettings &&
          other.behavior == behavior &&
          other.cachedValidDuration == cachedValidDuration &&
          // other.fallbackToAlternativeStore == fallbackToAlternativeStore &&
          other.recordHitsAndMisses == recordHitsAndMisses &&
          other.errorHandler == errorHandler &&
          other.obscuredQueryParams == obscuredQueryParams);

  @override
  int get hashCode => Object.hashAllUnordered([
        behavior,
        cachedValidDuration,
        // fallbackToAlternativeStore,
        recordHitsAndMisses,
        errorHandler,
        obscuredQueryParams,
      ]);
}
