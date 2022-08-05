import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> selectAndExportStore({
    String dialogTitle = 'Export Cache Store',
    String fileExtension = 'fmtc',
  }) async {
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: '${_storeDirectory.storeName}.$fileExtension',
      type: FileType.custom,
      allowedExtensions: [fileExtension],
    );

    if (outputPath != null) {
      await exportStore(File(outputPath));
    }
  }

  Future<void> exportStore(File outputFile) async {
    final String path = _access.absolute.path;
    await compute(_export, path);
    await File('$path.zip').rename(outputFile.absolute.path);
  }
}

void _export(String path) => ZipFileEncoder().zipDirectory(Directory(path));
