// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides statistics about a [RootDirectory]
class RootStats {
  RootStats._();

  FMTCRegistry get _registry => FMTCRegistry.instance;

  /// List all the available [StoreDirectory]s
  ///
  /// Prefer [storesAvailableAsync] to avoid blocking the UI thread. Otherwise,
  /// this has slightly better performance.
  List<StoreDirectory> get storesAvailable => _registry.registryDatabase.stores
      .where()
      .findAllSync()
      .map((s) => StoreDirectory._(s.name))
      .toList();

  /// List all the available [StoreDirectory]s
  Future<List<StoreDirectory>> get storesAvailableAsync async =>
      (await _registry.registryDatabase.stores.where().findAll())
          .map((s) => StoreDirectory._(s.name))
          .toList();

  /// Retrieve the total size of all stored tiles and the registry in kibibytes
  /// (KiB)
  ///
  /// Prefer [rootSizeAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  ///
  /// Internally sums up the size of all stores (using [StoreStats.storeSize])
  /// and the size of the registry database.
  double get rootSize =>
      (_registry.registryDatabase.getSizeSync() +
          storesAvailable.map((e) => e.stats.storeSize).sum) /
      1024;

  /// Retrieve the total size of all stored tiles and the registry in kibibytes
  /// (KiB)
  ///
  /// Internally sums up the size of all stores (using
  /// [StoreStats.storeSizeAsync]) and the size of the registry database.
  Future<double> get rootSizeAsync async =>
      (await _registry.registryDatabase.getSize() +
          (await Future.wait(
            storesAvailable.map((e) => e.stats.storeSizeAsync),
          ))
              .sum) /
      1024;

  /// Retrieve the number of all stored tiles
  ///
  /// Prefer [rootLengthAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  ///
  /// Internally sums up the length of all stores (using
  /// [StoreStats.storeLength]).
  int get rootLength => storesAvailable.map((e) => e.stats.storeLength).sum;

  /// Retrieve the number of all stored tiles
  ///
  /// Internally sums up the length of all stores (using
  /// [StoreStats.storeLengthAsync]).
  Future<int> get rootLengthAsync async =>
      (await Future.wait(storesAvailable.map((e) => e.stats.storeLengthAsync)))
          .sum;

  /// Watch for changes in the current root
  ///
  /// Useful to update UI only when required, for example, in a `StreamBuilder`.
  /// Whenever this has an event, it is likely the other statistics will have
  /// changed.
  ///
  /// Control where changes are caught from using [rootParts]. See documentation
  /// on those parts for their scope.
  ///
  /// Recursively watch specific stores (using [StoreStats.watchChanges]) by
  /// providing them as a list of [StoreDirectory]s to [recursive]. To watch all
  /// stores, use the [storesAvailable]/[storesAvailableAsync] getter as the
  /// argument.  By default, no sub-stores are watched (empty list), meaning only
  /// changes within the registry (eg. store creations) will be caught. Control
  /// where changes are caught from using [storeParts]. See documentation on
  /// those parts for their scope.
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
    List<StoreDirectory> recursive = const [],
    List<RootParts> rootParts = const [
      RootParts.stores,
      RootParts.recovery,
    ],
    List<StoreParts> storeParts = const [
      StoreParts.metadata,
      StoreParts.tiles,
      StoreParts.storeEntry,
    ],
  }) =>
      [
        if (rootParts.contains(RootParts.stores))
          _registry.registryDatabase.stores
              .watchLazy(fireImmediately: fireImmediately),
        if (rootParts.contains(RootParts.recovery))
          _registry.recoveryDatabase.stores
              .watchLazy(fireImmediately: fireImmediately),
        ...recursive.map(
          (s) => s.stats.watchChanges(
            fireImmediately: fireImmediately,
            storeParts: storeParts,
          ),
        ),
      ].reduce((v, e) => v.merge(e)).debounce(debounce ?? Duration.zero);
}
