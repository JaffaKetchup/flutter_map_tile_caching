// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Describes the result of a store's import
///
/// Property of [ImportResult].
enum ImportResultCategory {
  /// The store was imported successfully
  successful,

  /// There was an existing store with the same name and `overwriteExistingStore`
  /// was `false`
  collision,

  /// There was an unknown error during importing
  ///
  /// The database system should be in a stable state.
  unknown,
}

/// Describes a store import entity after success/failure
class ImportResult {
  ImportResult._({
    required this.path,
    required this.storeName,
    required this.result,
  });

  /// The path to the selected file
  final String path;

  /// The store name of the selected file (parsed from filename)
  final String storeName;

  /// Describes the status of the import
  final Future<ImportResultCategory> result;
}

/// Provides store import functionality for a [RootDirectory]
class RootImport {
  RootImport._();

  /// Import store(s) with the platform specifc file picker interface
  ///
  /// Where supported, the user will only be able to pick files with the
  /// [fileExtension] extension ('fmtc' by default). If not supported, any file
  /// can be picked, but only those with the [fileExtension] extension will be
  /// processed.
  ///
  /// Enabling [overwriteExistingStore] (defaults to `false`) will cause the
  /// import to overwrite any store of the same name.
  ///
  /// Disabling [emptyCacheBeforePicking] is not recommended (defaults to
  /// `true`). When disabled, the picker may use cached files as opposed to the
  /// real files, which may yield unexpected results. This is only effective on
  /// Android and iOS - other platforms cannot use caching.
  ///
  /// If any files are selected, a map of the selected filenames to whether that
  /// store was imported successfully is returned.
  Future<Iterable<ImportResult>?> withGUI({
    String fileExtension = 'fmtc',
    bool overwriteExistingStore = false,
    bool emptyCacheBeforePicking = true,
  }) async {
    if (emptyCacheBeforePicking && (Platform.isAndroid || Platform.isIOS)) {
      await FilePicker.platform.clearTemporaryFiles();
    }

    late final FilePickerResult? importPaths;
    try {
      importPaths = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Cache Stores',
        type: FileType.custom,
        allowedExtensions: [fileExtension],
        allowMultiple: true,
      );
    } on PlatformException catch (_) {
      importPaths = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Cache Stores',
        allowMultiple: true,
      );
    }

    if (importPaths == null) return null;

    return importPaths.files.where((f) => f.extension == fileExtension).map(
          (p) => manual(
            File(p.path!),
            overwriteExistingStore: overwriteExistingStore,
          ),
        );
  }

  /// Import a store from a specified [inputFile]
  ///
  /// Also see [withGUI] for a prebuilt solution to allow the user to select
  /// files to import.
  ///
  /// Enabling [overwriteExistingStore] (defaults to `false`) will cause the
  /// import to overwrite any store of the same name.
  ImportResult manual(
    File inputFile, {
    bool overwriteExistingStore = false,
  }) {
    final filename = path.basenameWithoutExtension(inputFile.path);
    final storeName =
        filename.substring(filename.startsWith('export_') ? 7 : 0);

    return ImportResult._(
      path: inputFile.absolute.path,
      storeName: storeName,
      result: (() async {
        if (FMTC.instance(storeName).manage.ready) {
          if (!overwriteExistingStore) return ImportResultCategory.collision;
          await FMTC.instance(storeName).manage.delete();
        }

        final id = DatabaseTools.hash(storeName);
        final newStorePath = FMTC.instance.rootDirectory.directory > '$id.isar';
        try {
          await inputFile.copy(newStorePath);
          FMTCRegistry.instance.storeDatabases[id] = await Isar.open(
            [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
            name: id.toString(),
            directory: FMTC.instance.rootDirectory.directory.path,
            maxSizeMiB: FMTC.instance.settings.databaseMaxSize,
            compactOnLaunch: FMTC.instance.settings.databaseCompactCondition,
          );
        } catch (_) {
          await File(newStorePath).delete();
          FMTCRegistry.instance.storeDatabases.remove(id);
          return ImportResultCategory.unknown;
        }

        return ImportResultCategory.successful;
      })(),
    );
  }
}
