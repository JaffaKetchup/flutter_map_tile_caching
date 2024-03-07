// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Callback type that takes an [FMTCBrowsingError] exception
typedef FMTCBrowsingErrorHandler = void Function(FMTCBrowsingError exception);

/// Behaviours dictating how and when browse caching should occur
///
/// An online only behaviour is not available: use a default [TileProvider] to
/// achieve this.
enum CacheBehavior {
  /// Only get tiles from the local cache
  ///
  /// Throws [FMTCBrowsingErrorType.missingInCacheOnlyMode] if a tile is
  /// unavailable.
  ///
  /// If [FMTCTileProviderSettings.fallbackToAlternativeStore] is enabled, cached
  /// tiles may also be taken from other stores.
  cacheOnly,

  /// Retrieve tiles from the cache, only using the network to update the cached
  /// tile if it has expired
  ///
  /// Falls back to using cached tiles if the network is not available.
  ///
  /// If [FMTCTileProviderSettings.fallbackToAlternativeStore] is enabled, and
  /// the network is unavailable, cached tiles may also be taken from other
  /// stores.
  cacheFirst,

  /// Get tiles from the network where possible, and update the cached tiles
  ///
  /// Falls back to using cached tiles if the network is unavailable.
  ///
  /// If [FMTCTileProviderSettings.fallbackToAlternativeStore] is enabled, cached
  /// tiles may also be taken from other stores.
  onlineFirst,
}

/// Settings for an [FMTCTileProvider]
class FMTCTileProviderSettings {
  /// Create new settings for an [FMTCTileProvider], and set the [instance] (if
  /// [setInstance] is `true`, as default)
  ///
  /// To access the existing settings, if any, get [instance].
  factory FMTCTileProviderSettings({
    CacheBehavior behavior = CacheBehavior.cacheFirst,
    bool fallbackToAlternativeStore = true,
    Duration cachedValidDuration = const Duration(days: 16),
    int maxStoreLength = 0,
    List<String> obscuredQueryParams = const [],
    FMTCBrowsingErrorHandler? errorHandler,
    bool setInstance = true,
  }) {
    final settings = FMTCTileProviderSettings._(
      behavior: behavior,
      fallbackToAlternativeStore: fallbackToAlternativeStore,
      cachedValidDuration: cachedValidDuration,
      maxStoreLength: maxStoreLength,
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
    required this.maxStoreLength,
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
  /// Does not add tiles taken from other stores to the specified store.
  ///
  /// When tiles are retrieved from other stores, it is counted as a miss for the
  /// specified store.
  ///
  /// See details on [CacheBehavior] for information. Fallback to an alternative
  /// store is always the last-resort option before throwing an error.
  final bool fallbackToAlternativeStore;

  /// The duration until a tile expires and needs to be fetched again when
  /// browsing. Also called `validDuration`.
  ///
  /// Defaults to 16 days, set to [Duration.zero] to disable.
  final Duration cachedValidDuration;

  /// The maximum number of tiles allowed in a cache store (only whilst
  /// 'browsing' - see below) before the oldest tile gets deleted. Also called
  /// `maxTiles`.
  ///
  /// Only applies to 'browse caching', ie. downloading regions will bypass this
  /// limit.
  ///
  /// Note that the database maximum size may be set by the backend.
  ///
  /// Defaults to 0 disabled.
  final int maxStoreLength;

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
          other.maxStoreLength == maxStoreLength &&
          other.errorHandler == errorHandler &&
          other.obscuredQueryParams == obscuredQueryParams);

  @override
  int get hashCode => Object.hashAllUnordered([
        behavior,
        cachedValidDuration,
        maxStoreLength,
        errorHandler,
        obscuredQueryParams,
      ]);
}
