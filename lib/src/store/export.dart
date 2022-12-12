// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../fmtc.dart';

/// Provides import and export functionality for a [StoreDirectory]
@internal
class StoreExport {
  StoreExport._(this._storeDirectory);
  final StoreDirectory _storeDirectory;

  /// Export the store with a graphical user interface (uses [manual] internally)
  ///
  /// Set [forceFilePicker] to:
  /// * `true`: always force an attempt at using the file picker. This will cause
  /// an error on unsupported platforms, and so is not recommended.
  /// * `false`: always force an attempt at using the share sheet. This will
  /// cause an error on unsupported platforms, and so is not recommended.
  /// * `null`: uses the platform specific file picker on desktop platforms, and
  /// the share dialog/sheet on mobile platforms.
  ///
  /// [context] ([BuildContext]) must be specified if using the share sheet, so
  /// it is necessary to pass it unless [forceFilePicker] is `true`. Will cause
  /// an unhandled null error if not passed when necessary.
  ///
  /// Exported files are named as the store name plus the [fileExtension] ('fmtc'
  /// by default).
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
