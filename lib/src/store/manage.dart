// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages an [FMTCStore]'s representation on the filesystem, such as
/// creation and deletion
///
/// If the store is not in the expected state (of existence) when invoking an
/// operation, then an error will be thrown ([StoreNotExists]). It is
/// recommended to check [ready] when necessary.
class StoreManagement {
  StoreManagement._(FMTCStore store) : _storeName = store.storeName;

  final String _storeName;

  /// {@macro fmtc.backend.storeExists}
  Future<bool> get ready =>
      FMTCBackendAccess.internal.storeExists(storeName: _storeName);

  /// {@macro fmtc.backend.createStore}
  Future<void> create() =>
      FMTCBackendAccess.internal.createStore(storeName: _storeName);

  /// {@macro fmtc.backend.deleteStore}
  Future<void> delete() =>
      FMTCBackendAccess.internal.deleteStore(storeName: _storeName);

  /// {@macro fmtc.backend.resetStore}
  Future<void> reset() =>
      FMTCBackendAccess.internal.resetStore(storeName: _storeName);

  /// {@macro fmtc.backend.renameStore}
  ///
  /// The old [FMTCStore] will still retain it's link to the old store, so
  /// always use the new returned value instead: returns a new [FMTCStore]
  /// after a successful renaming operation.
  Future<FMTCStore> rename(String newStoreName) async {
    await FMTCBackendAccess.internal.renameStore(
      currentStoreName: _storeName,
      newStoreName: newStoreName,
    );

    return FMTCStore(newStoreName);
  }

  /// {@macro fmtc.backend.removeTilesOlderThan}
  Future<void> removeTilesOlderThan({required DateTime expiry}) =>
      FMTCBackendAccess.internal
          .removeTilesOlderThan(storeName: _storeName, expiry: expiry);
}
