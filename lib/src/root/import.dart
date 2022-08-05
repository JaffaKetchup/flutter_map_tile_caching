import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../flutter_map_tile_caching.dart';
import '../internal/exts.dart';
import '../store/manage.dart';

/// Provides store import functionality for a [RootDirectory]
class RootImport {
  /// The root directory to import stores into
  final RootDirectory _rootDirectory;

  /// Provides store import functionality for a [RootDirectory]
  RootImport(this._rootDirectory);

  /// Import store(s) with a graphical user interface (uses [manual] internally)
  ///
  /// Uses the platform specifc file picker. Where supported, limits file extension to [fileExtension] ('fmtc' by default), otherwise any file can be selected as a fallback.
  ///
  /// If any files are selected, a [Map] is returned: where the keys are the the selected filenames (without extensions), and the values will resolve to a [bool] specifying whether the import was successful or unsuccessful. Otherwise `null` will be returned.
  Future<Map<String, Future<bool>>?> withGUI({
    String fileExtension = 'fmtc',
  }) async {
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
              p.basenameWithoutExtension(pf.name),
              manual(File(pf.path!)),
            ),
          ),
    );
  }

  /// Import a store from a specified [inputFile]
  ///
  /// It is recommended to use [withGUI] instead. This is only provided for finer control.
  ///
  /// The output specifies whether the import was successful or unsuccessful.
  Future<bool> manual(File inputFile) async {
    final String path = inputFile.absolute.path;
    final String storeName = p.basenameWithoutExtension(path);
    final StoreManagement storeManagement = StoreDirectory(
      _rootDirectory,
      storeName,
      autoCreate: false,
    ).manage;

    await compute(_import, {
      _rootDirectory.access.stores > storeName: await File(path).readAsBytes(),
    });

    if (await storeManagement.readyAsync) return true;
    await storeManagement.deleteAsync();
    return false;
  }
}

Future<void> _import(Map<String, Uint8List> data) async {
  final Directory baseDirectory = Directory(data.keys.toList()[0]);
  final Archive archive = ZipDecoder().decodeBytes(data.values.toList()[0]);

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
