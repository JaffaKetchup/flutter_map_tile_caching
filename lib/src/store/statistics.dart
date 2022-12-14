// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides statistics about a [StoreDirectory]
class StoreStats {
  StoreStats._(StoreDirectory storeDirectory)
      : _id = DatabaseTools.hash(storeDirectory.storeName);
  final int _id;

  Isar get _tiles => FMTCRegistry.instance.tileDatabases[_id]!;

  IsarCollection<DbStore> get _stores =>
      FMTCRegistry.instance.registryDatabase.stores;
  DbStore get _store => _stores.getSync(_id)!;
  Future<DbStore> get _storeAsync async => (await _stores.get(_id))!;

  /// Retrieve the total size of the stored tiles and metadata in kibibytes (KiB)
  ///
  /// Prefer [storeSizeAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  double get storeSize => _tiles.getSizeSync(includeIndexes: true) / 1024;

  /// Retrieve the total size of the stored tiles and metadata in kibibytes (KiB)
  Future<double> get storeSizeAsync async =>
      await _tiles.getSize(includeIndexes: true) / 1024;

  /// Retrieve the number of stored tiles
  ///
  /// Prefer [storeLengthAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  int get storeLength => _tiles.tiles.countSync();

  /// Retrieve the number of stored tiles
  Future<int> get storeLengthAsync => _tiles.tiles.count();

  /// Retrieve the number of tiles that were successfully retrieved from the
  /// store during browsing
  ///
  /// Prefer [cacheHitsAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  int get cacheHits => _store.hits;

  /// Retrieve the number of tiles that were successfully retrieved from the
  /// store during browsing
  Future<int> get cacheHitsAsync async => (await _storeAsync).hits;

  /// Retrieve the number of tiles that were unsuccessfully retrieved from the
  /// store during browsing
  ///
  /// Prefer [cacheMissesAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  int get cacheMisses => _store.misses;

  /// Retrieve the number of tiles that were unsuccessfully retrieved from the
  /// store during browsing
  Future<int> get cacheMissesAsync async => (await _storeAsync).misses;

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
      StoreParts.storeEntry,
    ],
  }) =>
      [
        if (storeParts.contains(StoreParts.metadata))
          _tiles.metadata.watchLazy(fireImmediately: fireImmediately),
        if (storeParts.contains(StoreParts.tiles))
          _tiles.tiles.watchLazy(fireImmediately: fireImmediately),
        if (storeParts.contains(StoreParts.storeEntry))
          _stores.watchObjectLazy(_id, fireImmediately: fireImmediately),
      ].reduce((v, e) => v.merge(e)).debounce(debounce ?? Duration.zero);
}
