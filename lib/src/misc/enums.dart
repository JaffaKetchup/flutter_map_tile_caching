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

/// Parts of the root cache which can be watched
enum RootParts {
  /// Watch changes within the recovery directory
  recovery,

  /// Watch changes about root statistics
  stats,

  /// Watch changes about sub-stores
  ///
  /// Note that this will not recursively watch within each store. For example, additions of new stores will be caught, but changes in statistics in each store will not.
  stores,
}

/// Parts of a store which can be watched
enum StoreParts {
  /// Watch changes within the metadata directory
  metadata,

  /// Watch changes about statistics
  stats,

  /// Watch changes within the tiles directory
  ///
  /// Usually not recommended to watch, due to the high frequency of changes.
  tiles,
}
