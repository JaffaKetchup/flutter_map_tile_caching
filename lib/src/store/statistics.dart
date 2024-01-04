// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Provides statistics about a [FMTCStore]
final class StoreStats extends _WithBackendAccess {
  const StoreStats._(super._store);

  /// {@macro fmtc.backend.getStoreSize}
  Future<double> get size => _backend.getStoreSize(storeName: _storeName);

  /// {@macro fmtc.backend.getStoreLength}
  Future<int> get length => _backend.getStoreLength(storeName: _storeName);

  /// {@macro fmtc.backend.getStoreHits}
  Future<int> get cacheHits async =>
      _backend.getStoreHits(storeName: _storeName);

  /// {@macro fmtc.backend.getStoreMisses}
  Future<int> get cacheMisses => _backend.getStoreMisses(storeName: _storeName);

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
