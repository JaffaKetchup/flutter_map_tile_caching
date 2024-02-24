// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Callback type that takes an [FMTCBrowsingError] exception
typedef FMTCBrowsingErrorHandler = void Function(FMTCBrowsingError exception);

/// Behaviours dictating how and when browse caching should be carried out
enum CacheBehavior {
  /// Only get tiles from the local cache
  ///
  /// Throws [FMTCBrowsingErrorType.missingInCacheOnlyMode] if a tile is not
  /// available.
  cacheOnly,

  /// Get tiles from the local cache, only using the network to update the cached
  /// tile if it has expired ([FMTCTileProviderSettings.cachedValidDuration] has
  /// passed)
  cacheFirst,

  /// Get tiles from the network where possible, and update the cached tiles
  ///
  /// Safely falls back to using cached tiles if the network is not available.
  onlineFirst,
}

/// Settings for an [FMTCTileProvider]
class FMTCTileProviderSettings {
  /// Create new settings for an [FMTCTileProvider], and set the [instance]
  ///
  /// To access the existing settings, if any, get [instance].
  factory FMTCTileProviderSettings({
    CacheBehavior behavior = CacheBehavior.cacheFirst,
    Duration cachedValidDuration = const Duration(days: 16),
    int maxStoreLength = 0,
    List<String> obscuredQueryParams = const [],
    FMTCBrowsingErrorHandler? errorHandler,
  }) =>
      _instance = FMTCTileProviderSettings._(
        behavior: behavior,
        cachedValidDuration: cachedValidDuration,
        maxStoreLength: maxStoreLength,
        obscuredQueryParams: obscuredQueryParams.map((e) => RegExp('$e=[^&]*')),
        errorHandler: errorHandler,
      );

  FMTCTileProviderSettings._({
    required this.behavior,
    required this.cachedValidDuration,
    required this.maxStoreLength,
    required this.obscuredQueryParams,
    required this.errorHandler,
  });

  /// Get an existing instance, if one has been constructed, or get the default
  /// intial configuration
  static FMTCTileProviderSettings get instance => _instance;
  static var _instance = FMTCTileProviderSettings();

  /// The behavior method to get and cache a tile
  ///
  /// Defaults to [CacheBehavior.cacheFirst] - get tiles from the local cache,
  /// going on the Internet to update the cached tile if it has expired
  /// ([cachedValidDuration] has passed).
  final CacheBehavior behavior;

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
