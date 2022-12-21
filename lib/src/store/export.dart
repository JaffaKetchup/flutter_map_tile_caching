// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides import and export functionality for a [StoreDirectory]
class StoreExport {
  StoreExport._(this._storeDirectory);
  final StoreDirectory _storeDirectory;

  /// Export the store with the platform specifc file picker interface or share
  /// sheet/dialog
  ///
  /// Set [forceFilePicker] to:
  ///
  /// * `null` (default): uses the platform specific file picker on desktop
  /// platforms, and the share dialog/sheet on mobile platforms.
  /// * `true`: always force an attempt at using the file picker. This will cause
  /// an error on unsupported platforms, and so is not recommended.
  /// * `false`: always force an attempt at using the share sheet. This will
  /// cause an error on unsupported platforms, and so is not recommended.
  ///
  /// [context] ([BuildContext]) must be specified if using the share sheet, so
  /// it is necessary to pass it unless [forceFilePicker] is `true`. Will cause
  /// an unhandled null error if not passed when necessary.
  ///
  /// Exported files are named in the format:
  /// `export_<storeName>.<fileExtension>`. The 'export' prefix will be removed
  /// automatically if present during importing.
  ///
  /// Returns `true` when successful, otherwise `false` when unsuccessful or
  /// unknown.
  Future<bool> withGUI({
    String fileExtension = 'fmtc',
    bool? forceFilePicker,
    BuildContext? context,
  }) async {
    if (forceFilePicker ??
        Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Cache Store',
        fileName: 'export_${_storeDirectory.storeName}.$fileExtension',
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );

      if (outputPath == null) return false;

      await manual(File(outputPath));
      return true;
    } else {
      final File exportFile = FMTC.instance.rootDirectory.directory >>>
          'export_${_storeDirectory.storeName}.$fileExtension';
      final box = context!.findRenderObject() as RenderBox?;

      await manual(exportFile);
      final ShareResult result = await Share.shareXFiles(
        [XFile(exportFile.absolute.path)],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      await exportFile.delete();

      return result.status == ShareResultStatus.success;
    }
  }

  /// Export the store to a specified [outputFile]
  ///
  /// See [withGUI] for a method that provides logic to show appropriate platform
  /// windows/sheets for export.
  Future<void> manual(File outputFile) => FMTCRegistry
      .instance.tileDatabases[DatabaseTools.hash(_storeDirectory.storeName)]!
      .copyToFile(outputFile.absolute.path);
}
