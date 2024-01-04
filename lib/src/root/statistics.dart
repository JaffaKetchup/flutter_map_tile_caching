// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Provides statistics about a [RootDirectory]
class RootStats {
  const RootStats._();

  FMTCRegistry get _registry => FMTCRegistry.instance;

  /// List all the available [FMTCStore]s synchronously
  ///
  /// Prefer [storesAvailableAsync] to avoid blocking the UI thread. Otherwise,
  /// this has slightly better performance.
  List<FMTCStore> get storesAvailable => _registry.storeDatabases.values
      .map((e) => FMTCStore._(e.descriptorSync.name, autoCreate: false))
      .toList();

  /// List all the available [FMTCStore]s asynchronously
  Future<List<FMTCStore>> get storesAvailableAsync => Future.wait(
        _registry.storeDatabases.values.map(
          (e) async =>
              FMTCStore._((await e.descriptor).name, autoCreate: false),
        ),
      );

  /// Retrieve the total size of all stored tiles in kibibytes (KiB)
  /// synchronously
  ///
  /// Prefer [rootSizeAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  ///
  /// Internally sums up the size of all stores (using [StoreStats.storeSize]).
  double get rootSize =>
      storesAvailable.map((e) => e.stats.storeSize).sum / 1024;

  /// Retrieve the total size of all stored tiles in kibibytes (KiB)
  /// asynchronously
  ///
  /// Internally sums up the size of all stores (using
  /// [StoreStats.storeSizeAsync]).
  Future<double> get rootSizeAsync async =>
      (await Future.wait(storesAvailable.map((e) => e.stats.storeSizeAsync)))
          .sum /
      1024;

  /// Retrieve the number of all stored tiles synchronously
  ///
  /// Prefer [rootLengthAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  ///
  /// Internally sums up the length of all stores (using
  /// [StoreStats.storeLength]).
  int get rootLength => storesAvailable.map((e) => e.stats.storeLength).sum;

  /// Retrieve the number of all stored tiles asynchronously
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
  /// Recursively watch specific stores (using [StoreStats.watchChanges]) by
  /// providing them as a list of [FMTCStore]s to [recursive]. To watch all
  /// stores, use the [storesAvailable]/[storesAvailableAsync] getter as the
  /// argument. By default, no sub-stores are watched (empty list), meaning only
  /// events that affect the actual store database (eg. store creations) will be
  /// caught. Control where changes are caught from using [storeParts]. See
  /// documentation on those parts for their scope.
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
    List<FMTCStore> recursive = const [],
    bool watchRecovery = false,
    List<StoreParts> storeParts = const [
      StoreParts.metadata,
      StoreParts.tiles,
      StoreParts.stats,
    ],
  }) =>
      StreamGroup.merge([
        DirectoryWatcher(FMTC.instance.rootDirectory.directory.absolute.path)
            .events
            .where((e) => !path.dirname(e.path).endsWith('import')),
        if (watchRecovery)
          _registry.recoveryDatabase.recovery
              .watchLazy(fireImmediately: fireImmediately),
        ...recursive.map(
          (s) => s.stats.watchChanges(
            fireImmediately: fireImmediately,
            storeParts: storeParts,
          ),
        ),
      ]).debounce(debounce ?? Duration.zero);
}
