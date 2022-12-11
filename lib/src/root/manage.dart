// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'directory.dart';

/// Manages a [RootDirectory]'s representation on the filesystem, such as
/// creation and deletion
class RootManagement {
  Directory get _rootDirectory => FMTC.instance.rootDirectory.rootDirectory;
  _RootAccess get _access => FMTC.instance.rootDirectory._access;

  /// Check whether the root directory exists and the root database is ready
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        _rootDirectory.exists(),
        (_rootDirectory >>> 'registry.isar').exists(),
      ]))
          .every((e) => e);

  /// Create the root directory and prepare the root database
  Future<void> createAsync() async {
    if (await readyAsync) return;

    await _rootDirectory.create(recursive: true);
    _access.rootDb = await Isar.open(
      [StoreSchema],
      name: 'registry',
      directory: _rootDirectory.absolute.path,
    );
    await _access.rescan();

    // TODO: REMOVE FOR PRODUCTION
    await _access.rootDb.writeTxn(() async {
      await _access.rootDb.clear();
      await _access.createStore('OpenStreetMap');
      await _access.createStore('Thunderforest Outdoors');
    });
  }

  /// Delete the root directory, database, and stores
  ///
  /// This will remove all traces of this root from the user's device. Use with
  /// caution!
  ///
  /// Returns an indicator as to whether the operation was successful.
  Future<bool> deleteAsync() async {
    await _access.rescan();
    if (!(await Future.wait(
      _access.storeDbs.values.map((i) => i.close(deleteFromDisk: true)),
    ))
        .every((e) => e)) return false;
    if (!await _access.rootDb.close(deleteFromDisk: true)) return false;
    await _rootDirectory.delete(recursive: true);
    await _access.rescan();
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
