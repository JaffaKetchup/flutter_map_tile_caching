// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Provides statistics about a [StoreDirectory]
final class StoreStats extends _WithBackendAccess {
  const StoreStats._(super._store);

  /// Retrieve the total size of the stored tiles and metadata in kibibytes (KiB)
  ///
  /// Prefer [storeSizeAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  double get storeSize => _backend.getStoreSizeSync(storeName: _storeName);

  /// Retrieve the total size of the stored tiles and metadata in kibibytes (KiB)
  Future<double> get storeSizeAsync =>
      _backend.getStoreSize(storeName: _storeName);

  /// Retrieve the number of stored tiles synchronously
  ///
  /// Prefer [storeLengthAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  int get storeLength => _backend.getStoreLengthSync(storeName: _storeName);

  /// Retrieve the number of stored tiles asynchronously
  Future<int> get storeLengthAsync =>
      _backend.getStoreLength(storeName: _storeName);

  /// Retrieve the number of tiles that were successfully retrieved from the
  /// store during browsing synchronously
  ///
  /// Prefer [cacheHitsAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  int get cacheHits => _backend.getStoreHitsSync(storeName: _storeName);

  /// Retrieve the number of tiles that were successfully retrieved from the
  /// store during browsing asynchronously
  Future<int> get cacheHitsAsync async =>
      _backend.getStoreHits(storeName: _storeName);

  /// Retrieve the number of tiles that were unsuccessfully retrieved from the
  /// store during browsing synchronously
  ///
  /// Prefer [cacheMissesAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  int get cacheMisses => _backend.getStoreMissesSync(storeName: _storeName);

  /// Retrieve the number of tiles that were unsuccessfully retrieved from the
  /// store during browsing asynchronously
  Future<int> get cacheMissesAsync async =>
      _backend.getStoreMisses(storeName: _storeName);

  /// Watch for changes in the current store
  ///
  /// Useful to update UI only when required, for example, in a `StreamBuilder`.
  /// Whenever this has an event, it is likely the other statistics will have
  /// changed.
  ///
  /// Control where changes are caught from using [storeParts]. See documentation
  /// on those parts for their scope.
  ///
  /// Enable debouncing to prevent unnecessary events for small changes in detail
  /// using [debounce]. Defaults to 200ms, or set to null to disable debouncing.
  ///
  /// Debouncing example (dash roughly represents [debounce]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  Stream<void> watchChanges({
    Duration? debounce = const Duration(milliseconds: 200),
    bool fireImmediately = false,
    List<StoreParts> storeParts = const [
      StoreParts.metadata,
      StoreParts.tiles,
      StoreParts.stats,
    ],
  }) =>
      throw UnimplementedError();
}

/// Parts of a store which can be watched
enum StoreParts {
  /// Include changes to the store's metadata objects
  metadata,

  /// Includes changes to the store's tile objects, including those which will
  /// make some statistics change (eg. store size)
  tiles,

  /// Includes changes to the store's descriptor object, which will change with
  /// the cache hit and miss statistics
  stats,
}
