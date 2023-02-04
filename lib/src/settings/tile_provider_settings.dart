// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';

import '../../flutter_map_tile_caching.dart';
import '../providers/image_provider.dart';

/// Multiple behaviors dictating how browse caching should be carried out
///
/// Check documentation on each value for more information.
enum CacheBehavior {
  /// Only get tiles from the local cache
  ///
  /// Useful for applications with dedicated 'Offline Mode'.
  cacheOnly,

  /// Get tiles from the local cache, going on the Internet to update the cached tile if it has expired (`cachedValidDuration` has passed)
  cacheFirst,

  /// Get tiles from the Internet and update the cache for every tile
  onlineFirst,
}

/// Settings for an [FMTCTileProvider]
class FMTCTileProviderSettings {
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
  /// Note that the actual store has an un-modifiable maximum size limit of
  /// [Isar.defaultMaxSizeMiB] (1GB). It is unspecified what will happen if this
  /// limit is reached, however it is likely that an error will be thrown.
  ///
  /// Defaults to 0 disabled.
  final int maxStoreLength;

  /// A custom callback that will be called when an [FMTCBrowsingError] is raised
  ///
  /// Prevents the error being printed to the console, and only captures this
  /// type of error, unlike 'flutter_map's native solution.
  void Function(FMTCBrowsingError exception)? errorHandler;

  /// Create settings for an [FMTCTileProvider]
  FMTCTileProviderSettings({
    this.behavior = CacheBehavior.cacheFirst,
    this.cachedValidDuration = const Duration(days: 16),
    this.maxStoreLength = 0,
    this.errorHandler,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FMTCTileProviderSettings &&
          other.behavior == behavior &&
          other.cachedValidDuration == cachedValidDuration &&
          other.maxStoreLength == maxStoreLength &&
          other.errorHandler == errorHandler);

  @override
  int get hashCode =>
      behavior.hashCode ^
      cachedValidDuration.hashCode ^
      maxStoreLength.hashCode ^
      errorHandler.hashCode;
}
