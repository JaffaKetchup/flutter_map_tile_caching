import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../internal/exts.dart';
import 'directory.dart';

/// Provides store import functionality for a [RootDirectory]
class RootImport {
  /// The root directory to import stores into
  final RootDirectory _rootDirectory;

  /// Provides store import functionality for a [RootDirectory]
  RootImport(this._rootDirectory);

  Future<void> selectAndImportStores({
    String dialogTitle = 'Import Cache Stores',
    String fileExtension = 'fmtc',
  }) async {
    final FilePickerResult? importPaths = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: [fileExtension],
    );

    if (importPaths != null) {
      await Future.wait(
        importPaths.paths.whereNotNull().map((p) => importStore(File(p))),
      );
    }
  }

  Future<void> importStore(File inputFile) async {
    final String path = inputFile.absolute.path;
    final Directory baseDirectory =
        _rootDirectory.access.stores >> p.basenameWithoutExtension(path);

    final Archive archive =
        await compute(_import, await File(path).readAsBytes());

    await Future.wait(
      [
        archive.where((f) => f.isFile).map(
              (f) async =>
                  (await (baseDirectory >>> f.name).create(recursive: true))
                      .writeAsBytes(f.content),
            ),
        archive
            .where((f) => !f.isFile)
            .map((f) => (baseDirectory >> f.name).create(recursive: true)),
      ].expand((e) => e),
    );
  }
}

Archive _import(List<int> data) => ZipDecoder().decodeBytes(data);
