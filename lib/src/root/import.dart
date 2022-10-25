// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

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
  /// It is recommended to leave [emptyCacheBeforePicking] as the default (`true`). Otherwise, the picker may use cached files as opposed to the real files, which may yield unexpected results. This is only effective on Android and iOS - other platforms cannot use caching.
  ///
  /// If any files are selected, a [Map] is returned: where the keys are the the selected filenames (without extensions), and the values will resolve to a [bool] specifying whether the import was successful or unsuccessful. Otherwise `null` will be returned.
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
    Future<bool> error(StoreManagement storeManagement) async {
      await storeManagement.deleteAsync();
      return false;
    }

    final String storeName =
        p.basenameWithoutExtension(inputFile.absolute.path);
    final StoreManagement storeManagement =
        StoreDirectory(_rootDirectory, storeName, autoCreate: false).manage;

    await compute(_import, {
      _rootDirectory.access.stores > storeName:
          await File(inputFile.absolute.path).readAsBytes(),
    });

    if (await storeManagement.readyAsync) return true;
    return error(storeManagement);
  }
}

void _import(Map<String, Uint8List> data) {
  final Directory dir = Directory(data.keys.toList()[0]);
  final Archive archive = ZipDecoder().decodeBytes(data.values.toList()[0]);

  for (final f in archive) {
    if (f.isFile) {
      (dir >>> f.name)
        ..createSync(recursive: true)
        ..writeAsBytesSync(f.content);
    } else {
      (dir >> f.name).createSync(recursive: true);
    }
  }
}
