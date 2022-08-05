import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../internal/exts.dart';
import 'access.dart';
import 'directory.dart';

/// Provides import and export functionality for a [StoreDirectory]
class StoreExport {
  /// The store directory to provide sharing functionality for
  final StoreDirectory _storeDirectory;

  /// Provides import and export functionality for a [StoreDirectory]
  StoreExport(this._storeDirectory)
      : _access = StoreAccess(_storeDirectory).real;

  /// Shorthand for [StoreAccess.real], used commonly throughout
  final Directory _access;

  /// Export the store with a graphical user interface (uses [manual] internally)
  ///
  /// By default, uses the platform specifc file picker on Windows, MacOS, or Windows, and the share dialog/sheet on other platforms (inferred to be Android or iOS).
  ///
  /// Exported files are named as the store name plus the [fileExtension] ('fmtc' by default).
  ///
  /// Set [forceFilePicker] to:
  /// * `true`: always force an attempt at using the file picker. This will cause an error on unsupported platforms, and so is not recommended.
  /// * `false`: always force an attempt at using the share dialog/sheet. This will cause an error on unsupported platforms, and so is not recommended.
  /// * `null`: use default as above
  ///
  /// [context] ([BuildContext]) must be specified if using the share dialog/sheet, so it is recommended to always pass it. Will cause a null error if not passed when necessary.
  Future<void> withGUI({
    String fileExtension = 'fmtc',
    bool? forceFilePicker,
    BuildContext? context,
  }) async {
    if (forceFilePicker ??
        Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Cache Store',
        fileName: '${_storeDirectory.storeName}.$fileExtension',
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );

      if (outputPath != null) {
        await manual(File(outputPath));
      }
    } else {
      final File exportFile =
          _access >>> '${_storeDirectory.storeName}.$fileExtension';
      final box = context!.findRenderObject() as RenderBox?;

      await manual(exportFile);
      await Share.shareFiles(
        [exportFile.absolute.path],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      await exportFile.delete();
    }
  }

  /// Export the store to a specified [outputFile]
  ///
  /// It is recommended to use [withGUI] instead. This is only provided for finer control.
  Future<void> manual(File outputFile) async {
    final String path = _access.absolute.path;
    await compute(_export, path);
    await File('$path.zip').rename(outputFile.absolute.path);
  }
}

void _export(String path) => ZipFileEncoder().zipDirectory(Directory(path));
