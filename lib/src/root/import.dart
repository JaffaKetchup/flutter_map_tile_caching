// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

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
  /// If any files are selected, a map of the selected filenames to whether that
  /// store was imported successfully is returned.
  Future<Map<String, Future<bool>>?> withGUI({
    String fileExtension = 'fmtc',
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

    return Map.fromEntries(
      importPaths.files.where((f) => f.extension == fileExtension).map(
            (pf) => MapEntry(
              path.basenameWithoutExtension(pf.name),
              manual(File(pf.path!)),
            ),
          ),
    );
  }

  /// Import a store from a specified [inputFile]
  ///
  /// It is recommended to use [withGUI] instead. This is only provided for finer
  /// control.
  ///
  /// The output specifies whether the import was successful or unsuccessful.
  Future<bool> manual(File inputFile) async {
    final filename = path.basenameWithoutExtension(inputFile.path);
    final storeName =
        filename.substring(filename.startsWith('export_') ? 7 : 0);

    final registry = FMTCRegistry.instance;

    await inputFile.copy(
      FMTC.instance.rootDirectory.directory >
          '${await FMTC.instance(storeName).manage._advancedCreate(synchronise: false)}.isar',
    );
    await registry.synchronise();

    return FMTC.instance(storeName).manage.ready;
  }
}
