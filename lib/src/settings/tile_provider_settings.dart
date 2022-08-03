import '../internal/tile_provider.dart';
import '../misc/enums.dart';

/// Settings for an [FMTCTileProvider]
class FMTCTileProviderSettings {
  /// The behavior method to get and cache a tile
  ///
  /// Defaults to [CacheBehavior.cacheFirst] - get tiles from the local cache, going on the Internet to update the cached tile if it has expired ([cachedValidDuration] has passed).
  final CacheBehavior behavior;

  /// The duration until a tile expires and needs to be fetched again when browsing. Also called `validDuration`.
  ///
  /// Defaults to 16 days, set to [Duration.zero] to disable.
  final Duration cachedValidDuration;

  /// The maximum number of tiles allowed in a cache store (only whilst 'browsing' - see below) before the oldest tile gets deleted. Also called `maxTiles`.
  ///
  /// Only applies to 'browse caching', ie. downloading regions will bypass this limit. This can be computationally expensive as it potentially involves sorting through this many files to find the oldest file.
  ///
  /// Please note that this limit is a 'suggestion'. Due to the nature of the application, it is difficult to set a hard limit on a the store's length. Therefore, fast browsing may go above this limit.
  ///
  /// Defaults to 0 disabled.
  final int maxStoreLength;

  /// Create settings for an [FMTCTileProvider]
  FMTCTileProviderSettings({
    this.behavior = CacheBehavior.cacheFirst,
    this.cachedValidDuration = const Duration(days: 16),
    this.maxStoreLength = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FMTCTileProviderSettings &&
        other.behavior == behavior &&
        other.cachedValidDuration == cachedValidDuration &&
        other.maxStoreLength == maxStoreLength;
  }

  @override
  int get hashCode =>
      behavior.hashCode ^
      cachedValidDuration.hashCode ^
      maxStoreLength.hashCode;
}
