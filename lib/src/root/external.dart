// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// The result of [RootExternal.import]
///
/// `stores` will complete when the store names become available, and whether
/// they have conflicted with existing stores.
///
/// `complete` will complete when the import is complete.
typedef ImportResult = ({
  Future<List<({String importingName, bool conflict, String? newName})>> stores,
  Future<void> complete,
});

/// Export & import 'archives' of selected stores and tiles, outside of the
/// FMTC environment
///
/// Archives are backend specific, and FMTC specific. They cannot necessarily
/// be imported by a backend different to the one that exported it. The
/// archive may hold a similar form to the raw format of the database used by
/// the backend, but FMTC specific information has been attached, and therefore
/// the file will be unreadable by non-FMTC database implementations.
///
/// If the specified archive (at [pathToArchive]) is not of the expected format,
/// an error from the [ImportExportError] group:
///
///  - Doesn't exist (except [export]): [ImportPathNotExists]
///  - Not a file: [ImportExportPathNotFile]
///  - Not an FMTC archive: [ImportFileNotFMTCStandard]
///  - Not compatible with the current backend: [ImportFileNotBackendCompatible]
///
/// Importing (especially) and exporting operations are likely to be slow. It is
/// not recommended to attempt to use other FMTC operations during the
/// operation, to avoid slowing it further or potentially causing inconsistent
/// state.
class RootExternal {
  const RootExternal._(this.pathToArchive);

  /// The path to an archive file
  final String pathToArchive;

  /// Creates an archive at [pathToArchive] containing the specified stores and
  /// their tiles
  ///
  /// If a file already exists at [pathToArchive], it will be overwritten.
  Future<void> export({
    required List<String> storeNames,
  }) =>
      FMTCBackendAccess.internal
          .exportStores(storeNames: storeNames, path: pathToArchive);

  /// CAUTION: HIGHLY EXPERIMENTAL, INCOMPLETE, AND UNTESTED
  @experimental
  Future<ImportResult> import({
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    List<String>? storeNames,
  }) =>
      FMTCBackendAccess.internal.importStores(
        path: pathToArchive,
        strategy: strategy,
        storeNames: storeNames,
      );

  /// List the available store names within the archive at [pathToArchive]
  Future<List<String>> get listStores =>
      FMTCBackendAccess.internal.listImportableStores(path: pathToArchive);
}

/// Determines what action should be taken when an importing store conflicts
/// with an existing store of the same name
///
/// If speed is a necessity, prefer using [skip] or [replace].
///
/// See documentation on individual values for more information.
enum ImportConflictStrategy {
  /// Deletes all existing stores, and imports all new stores
  ///
  /// This is significantly quicker than other options, as it only requires
  /// a few filesystem operations and quicker calculations to complete, but is
  /// mostly intended for situations where an archive is being shipped to new
  /// users.
  restart,

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
