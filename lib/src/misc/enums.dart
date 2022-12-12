// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

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

/// Parts of a store which can be watched
enum StoreParts {
  /// 'metadata' is deprecated and shouldn't be used. Prefer [storeEntry] and
  /// This remnant will be removed in a future update, and is currently non-
  /// functional.
  @Deprecated(
    "Prefer 'storeEntry'. This redirect will be removed in a future update",
  )
  metadata,

  /// 'stats' is deprecated and shouldn't be used. Prefer [tiles] and
  /// [storeEntry]. This remnant will be removed in a future update, and is
  /// currently non-functional.
  @Deprecated(
    "Prefer 'tiles' and 'storeEntry'. This redirect will be removed in a future update",
  )
  stats,

  /// Includes changes found directly in the store entry in the registry,
  /// including those which will make some statistics change (eg. cache hits)
  storeEntry,

  /// Includes changes within the tiles database, including those which will make
  /// some statistics change (eg. store size)
  tiles,
}
