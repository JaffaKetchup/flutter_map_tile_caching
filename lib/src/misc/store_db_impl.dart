part of flutter_map_tile_caching;

abstract class _StoreDb {
  const _StoreDb(this._store);

  final StoreDirectory _store;
  Isar get _db => FMTCRegistry.instance(_store.storeName);
}
