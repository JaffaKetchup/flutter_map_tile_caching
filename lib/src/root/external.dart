// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

typedef ImportResult = ({
  Future<List<({String importingName, bool conflict, String? newName})>> stores,
  Future<void> complete,
});

class RootExternal {
  const RootExternal._();

  Future<void> export({
    required List<String> storeNames,
    required String outputPath,
  }) =>
      FMTCBackendAccess.internal
          .exportStores(storeNames: storeNames, outputPath: outputPath);

  ImportResult import({
    required String path,
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
  }) =>
      FMTCBackendAccess.internal.importStores(
        path: path,
        strategy: strategy,
      );
}

/// Determines what action should be taken when an importing store conflicts
/// with an existing store of the same name
///
/// If speed is a necessity, prefer using [skip] or [replace].
///
/// See documentation on individual values for more information.
enum ImportConflictStrategy {
  /// Skips the importing of the store
  skip,

  /// Entirely replaces the existing store with the importing store
  ///
  /// Tiles from the existing store are deleted if they become orphaned (and do
  /// not belong to the importing store).
  replace,

  /// Renames the importing store by appending it with the current time (which
  /// should be unique in all reasonable usecases)
  ///
  /// All tiles are retained. In the event of a conflict between two tiles, only
  /// the one modified most recently is retained.
  rename,

  /// Merges the importing and existing stores' tiles and metadata together
  ///
  /// All tiles are retained. In the event of a conflict between two tiles, only
  /// the one modified most recently is retained.
  merge;
}
