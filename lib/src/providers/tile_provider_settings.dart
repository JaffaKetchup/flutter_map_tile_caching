// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Callback type that takes an [FMTCBrowsingError] exception
typedef FMTCBrowsingErrorHandler = void Function(FMTCBrowsingError exception);

/// Behaviours dictating how and when browse caching should occur
///
/// | `CacheBehavior`          | Preferred fetch method | Fallback fetch method | Update cache when network used |
/// |--------------------------|------------------------|-----------------------|--------------------------------|
/// | `cacheOnly`              | Cache                  | None                  |                                |
/// | `cacheFirst`             | Cache                  | Network               | Yes                            |
/// | `cacheFirstNoUpdate`     | Cache                  | Network               | No                             |
/// | `onlineFirst`            | Network                | Cache                 | Yes                            |
/// | `onlineFirstNoUpdate`    | Network                | Cache                 | No                             |
/// | *Standard Tile Provider* | *Network*              | *None*                | *No*                           |
enum CacheBehavior {
  /// Only fetch tiles from the local cache
  ///
  /// Throws [FMTCBrowsingErrorType.missingInCacheOnlyMode] if a tile is
  /// unavailable.
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheOnly,

  /// Fetch tiles from the cache, falling back to the network to fetch and
  /// create/update non-existent/expired tiles
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheFirst,

  /// Fetch tiles from the cache, falling back to the network to fetch
  /// non-existent tiles
  ///
  /// Never updates the cache, even if the network is used to fetch the tile.
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  cacheFirstNoUpdate,

  /// Fetch and create/update non-existent/expired tiles from the network,
  /// falling back to the cache to fetch tiles
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  onlineFirst,

  /// Fetch tiles from the network, falling back to the cache to fetch tiles
  ///
  /// Never updates the cache, even if the network is used to fetch the tile.
  ///
  /// See documentation on [CacheBehavior] for behavior comparison table.
  onlineFirstNoUpdate,
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
    bool fallbackToAlternativeStore = true,
    Duration cachedValidDuration = const Duration(days: 16),
    bool trackHitsAndMisses = true,
    List<String> obscuredQueryParams = const [],
    FMTCBrowsingErrorHandler? errorHandler,
    bool setInstance = true,
  }) {
    final settings = FMTCTileProviderSettings._(
      behavior: behavior,
      fallbackToAlternativeStore: fallbackToAlternativeStore,
      recordHitsAndMisses: trackHitsAndMisses,
      cachedValidDuration: cachedValidDuration,
      obscuredQueryParams: obscuredQueryParams.map((e) => RegExp('$e=[^&]*')),
      errorHandler: errorHandler,
    );

    if (setInstance) _instance = settings;
    return settings;
  }

  FMTCTileProviderSettings._({
    required this.behavior,
    required this.cachedValidDuration,
    required this.fallbackToAlternativeStore,
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

  /// Whether to retrieve a tile from another store if it exists, as a fallback,
  /// instead of throwing an error
  ///
  /// Does not add tiles taken from other stores to the specified store(s).
  ///
  /// When tiles are retrieved from other stores, it is counted as a miss for the
  /// specified store(s).
  ///
  /// This may introduce notable performance reductions, especially if failures
  /// occur often or the root is particularly large, as an extra lookup with
  /// unbounded constraints is required for each tile.
  ///
  /// See details on [CacheBehavior] for information. Fallback to an alternative
  /// store is always the last-resort option before throwing an error.
  ///
  /// Defaults to `true`.
  final bool fallbackToAlternativeStore;

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
  /// Even if this is defined, the error will still be (re)thrown.
  void Function(FMTCBrowsingError exception)? errorHandler;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProviderSettings &&
          other.behavior == behavior &&
          other.cachedValidDuration == cachedValidDuration &&
          other.fallbackToAlternativeStore == fallbackToAlternativeStore &&
          other.recordHitsAndMisses == recordHitsAndMisses &&
          other.errorHandler == errorHandler &&
          other.obscuredQueryParams == obscuredQueryParams);

  @override
  int get hashCode => Object.hashAllUnordered([
        behavior,
        cachedValidDuration,
        fallbackToAlternativeStore,
        recordHitsAndMisses,
        errorHandler,
        obscuredQueryParams,
      ]);
}
