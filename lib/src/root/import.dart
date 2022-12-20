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

  /// Import store(s) with a graphical user interface (uses [manual] internally)
  ///
  /// Uses the platform specifc file picker. Where supported, limits file
  /// extension to [fileExtension] ('fmtc' by default), otherwise any file can
  /// be selected as a fallback.
  ///
  /// It is recommended to leave [emptyCacheBeforePicking] as the default
  /// (`true`). Otherwise, the picker may use cached files as opposed to the real
  /// files, which may yield unexpected results. This is only effective on
  /// Android and iOS - other platforms cannot use caching.
  ///
  /// [overwriteExistingStore] (defaults to `false`) will cause the import to
  /// overwrite any store of the same name.
  ///
  /// If any files are selected, a map of the selected filenames to whether that
  /// store was imported successfully is returned.
  Future<Iterable<ImportResult>?> withGUI({
    String fileExtension = 'fmtc',
    bool emptyCacheBeforePicking = true,
    bool overwriteExistingStore = false,
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
  /// [overwriteExistingStore] (defaults to `false`) will cause the import to
  /// overwrite any store of the same name.
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
        if (await FMTC.instance(storeName).manage.ready) {
          if (!overwriteExistingStore) return ImportResultCategory.collision;
          await FMTC.instance(storeName).manage.delete();
        }

        final newStorePath = FMTC.instance.rootDirectory.directory >
            '${await FMTC.instance(storeName).manage._advancedCreate(synchronise: false)}.isar';
        try {
          await inputFile.copy(newStorePath);
          await FMTCRegistry.instance.synchronise();
        } catch (_) {
          await File(newStorePath).delete();
          await FMTCRegistry.instance.synchronise();
          return ImportResultCategory.unknown;
        }

        return ImportResultCategory.successful;
      })(),
    );
  }
}
