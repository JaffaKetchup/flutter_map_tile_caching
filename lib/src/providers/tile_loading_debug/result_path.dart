// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Methods that a tile can complete loading successfully
enum TileLoadingDebugResultPath {
  /// The tile was retrieved from:
  ///
  /// * the specified stores
  /// * the unspecified stores, if
  /// [FMTCTileProviderSettings.useOtherStoresAsFallbackOnly] is `false`
  perfectFromStores,

  /// The specified [CacheBehavior] was [CacheBehavior.cacheOnly], and the tile
  /// was retrieved from the cache (as a fallback)
  cacheOnlyFromOtherStores,

  /// The tile was retrieved from the cache as a fallback
  noFetch,

  /// The tile was newly fetched from the network
  fetched,
}
