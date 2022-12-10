// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:isar/isar.dart';

import '../db/defs/store.dart';
import '../fmtc.dart';
import '../internal/exts.dart';
import 'directory.dart';

/// Manages a [RootDirectory]'s representation on the filesystem, such as
/// creation and deletion
class RootManagement {
  Directory get _rootDirectory => FMTC.instance.rootDirectory.rootDirectory;
  Map<String, Isar> get _databases => FMTC.instance.databases;

  /// Check whether the root directory exists and the root database is ready
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        _rootDirectory.exists(),
        (_rootDirectory >>> 'fmtcRoot.isar').exists(),
      ]))
          .every((e) => e);

  /// Create the root directory and prepare the root database
  Future<void> createAsync() async {
    if (await readyAsync) return;

    await _rootDirectory.create(recursive: true);
    _databases[''] = await Isar.open(
      [StoreSchema],
      name: 'fmtcRoot',
      directory: _rootDirectory.absolute.path,
    );

    // TODO: REMOVE FOR PRODUCTION
    await FMTC.instance.databases['']!.writeTxn(() async {
      await FMTC.instance.databases['']!.clear();
      await FMTC.instance.databases['']!.stores
          .put(Store(name: 'OpenStreetMap'));
      await FMTC.instance.databases['']!.stores
          .put(Store(name: 'Thunderforest Outdoors'));
    });
  }

  /// Delete the root directory, database, and stores
  ///
  /// This will remove all traces of this root from the user's device. Use with
  /// caution!
  ///
  /// Returns an indicator as to whether the operation was successful.
  Future<bool> deleteAsync() async {
    if (!(await Future.wait(
      _databases.values.map((i) => i.close(deleteFromDisk: true)),
    ))
        .every((e) => e)) return false;

    await _rootDirectory.delete(recursive: true);
    _databases.clear();
    return true;
  }

  /// Empty/reset all of the root directory, database, and stores asynchronously
  ///
  /// This will remove all traces of this root from the user's device. Use with
  /// caution!
  ///
  /// Internally calls [deleteAsync] and [createAsync] to achieve effect.
  ///
  /// Returns an indicator as to whether the operation was successful.
  Future<bool> resetAsync() async {
    if (!await deleteAsync()) return false;
    await createAsync();
    return true;
  }
}
