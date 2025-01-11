// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// The result of [RootExternal.import]
///
/// `storesToStates` will complete when the final store names become available.
/// See [StoresToStates] for more information.
///
/// `complete` will complete when the import is complete, with the number of
/// imported/overwritten tiles.
typedef ImportResult = ({
  Future<StoresToStates> storesToStates,
  Future<int> complete,
});

/// A mapping of the original store name (as exported), to:
///  - its new store `name` (as will be used to import), or `null` if
/// [ImportConflictStrategy.skip] was set (meaning it won't be importing)
///  - whether it `hadConflict` with an existing store
///
/// Used in [ImportResult].
typedef StoresToStates = Map<String, ({String? name, bool hadConflict})>;

/// Export & import 'archives' of selected stores and tiles, outside of the
/// FMTC environment
///
/// ---
///
/// Archives are backend specific. They cannot be imported by a backend
/// different to the one that exported it.
///
/// Archives are only readable by FMTC. The archive may hold a similar form to
/// the raw format of the database used by the backend, but FMTC-specific
/// information has been attached, and therefore the file will be unreadable by
/// non-FMTC database implementations.
///
/// Archives are potentially backend/FMTC version specific, dependent on whether
/// the database schema was changed. An archive created on an older schema is
/// usually importable into a newer schema, but this is not guaranteed. An
/// archive created in a newer schema cannot be imported into an older schema.
/// Note that this is not enforced by the archive format, and the schema may not
/// change between FMTC or backend version changes.
///
/// ---
///
/// Importing (especially) and exporting operations are likely to be slow. It is
/// not recommended to attempt to use other FMTC operations during the
/// operation, to avoid slowing it further or potentially causing inconsistent
/// state.
///
/// Importing and exporting operations may consume more storage capacity than
/// expected, especially temporarily during the operation.
class RootExternal {
  const RootExternal._(this.pathToArchive);

  /// The path to an archive file (which may or may not exist)
  ///
  /// It should only point to a file. When used with [export], the file does not
  /// have to exist. Otherwise, it should exist.
  ///
  /// > [!IMPORTANT]
  /// > The path must be accessible to the application. For example, on Android
  /// > devices, it should not be in external storage, unless the app has the
  /// > appropriate (dangerous) permissions.
  /// >
  /// > On mobile platforms (/those platforms which operate sandboxed storage),
  /// > if the app does not have external storage permissions, it is recommended
  /// > to set this path to a path the application can definitely control (such
  /// > as app support), using a path from 'package:path_provider', then share
  /// > it somewhere else using the system flow (using 'package:share_plus').
  final String pathToArchive;

  /// Creates an archive at [pathToArchive] containing the specified stores and
  /// their tiles
  ///
  /// If [pathToArchive] already exists as a file, it will be overwritten. It
  /// must not already exist as anything other than a file. The path must be
  /// accessible to the application: see [pathToArchive] for information.
  ///
  /// The specified stores must contain at least one tile.
  ///
  /// Returns the number of exported tiles.
  Future<int> export({
    required List<String> storeNames,
  }) =>
      FMTCBackendAccess.internal
          .exportStores(storeNames: storeNames, path: pathToArchive);

  /// Imports specified stores and all necessary tiles into the current root
  /// from [pathToArchive]
  ///
  /// {@template fmtc.external.import.pathToArchiveRequirements}
  /// [pathToArchive] must exist as an compatible file. The path must be
  /// accessible to the application: see [pathToArchive] for information. If it
  /// does not exist, [ImportPathNotExists] will be thrown. If it exists, but is
  /// not a file, [ImportExportPathNotFile] will be thrown. If it exists, but is
  /// not an FMTC archive, [ImportFileNotFMTCStandard] will be thrown. If it is
  /// an FMTC archive, but not compatible with the current backend,
  /// [ImportFileNotBackendCompatible] will be thrown.
  /// {@endtemplate}
  ///
  /// See [ImportConflictStrategy] to set how conflicts between existing and
  /// importing stores should be resolved. Defaults to
  /// [ImportConflictStrategy.rename].
  ImportResult import({
    List<String>? storeNames,
    ImportConflictStrategy strategy = ImportConflictStrategy.rename,
  }) =>
      FMTCBackendAccess.internal.importStores(
        path: pathToArchive,
        storeNames: storeNames,
        strategy: strategy,
      );

  /// List the available store names within the archive at [pathToArchive]
  ///
  /// {@macro fmtc.external.import.pathToArchiveRequirements}
  Future<List<String>> get listStores =>
      FMTCBackendAccess.internal.listImportableStores(path: pathToArchive);
}

/// Determines what action should be taken when an importing store conflicts
/// with an existing store of the same name
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

  /// Renames the importing store by appending it with the current date & time
  /// (which should be unique in all reasonable usecases)
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
