// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Provides statistics about an [FMTCStore]
///
/// If the store is not in the expected state (of existence) when invoking an
/// operation, then an error will be thrown (likely [StoreNotExists] or
/// [StoreAlreadyExists]). It is recommended to check [StoreManagement.ready]
/// when necessary.
class StoreStats {
  StoreStats._(FMTCStore store) : _storeName = store.storeName;

  final String _storeName;

  /// {@macro fmtc.backend.getStoreStats}
  ///
  /// {@template fmtc.frontend.storestats.efficiency}
  /// Prefer using [all] when multiple statistics are required instead of getting
  /// them individually. Only one backend operation is required to get all the
  /// stats, and so is more efficient.
  /// {@endtemplate}
  Future<({double size, int length, int hits, int misses})> get all =>
      FMTCBackendAccess.internal.getStoreStats(storeName: _storeName);

  /// Retrieve the total number of KiBs of all tiles' bytes (not 'real total'
  /// size)
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  Future<double> get size => all.then((a) => a.size);

  /// Retrieve the number of tiles belonging to this store
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  Future<int> get length => all.then((a) => a.length);

  /// Retrieve the number of successful tile retrievals when browsing
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  Future<int> get hits => all.then((a) => a.hits);

  /// Retrieve number of unsuccessful tile retrievals when browsing
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  Future<int> get misses => all.then((a) => a.misses);

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
      // TODO: Implement
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
