// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: use_late_for_private_fields_and_variables

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

  /// {@macro fmtc.backend.watchStores}
  Stream<void> watchChanges({
    bool triggerImmediately = false,
  }) async* {
    final stream = FMTCBackendAccess.internal.watchStores(
      storeNames: [_storeName],
      triggerImmediately: triggerImmediately,
    );
    yield* stream;
  }
}
