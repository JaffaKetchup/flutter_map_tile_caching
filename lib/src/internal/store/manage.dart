import 'dart:io';

import 'package:path/path.dart' as p;

import '../../misc/validate.dart';
import 'access.dart';
import 'directory.dart';
import 'metadata.dart';
import 'statistics.dart';

/// Manages a [StoreDirectory]'s representation on the filesystem, such as creation and deletion
class StoreManagement {
  /// The store directory to manage
  final StoreDirectory _storeDirectory;

  /// Manages a [StoreDirectory]'s representation on the filesystem, such as creation and deletion
  StoreManagement(this._storeDirectory)
      : _access = StoreAccess(_storeDirectory);

  /// Shorthand for [StoreDirectory.access], used commonly throughout
  final StoreAccess _access;

  /// Check whether all directories exist synchronously
  bool get ready => [
        _access.tiles.existsSync(),
        _access.stats.existsSync(),
        _access.metadata.existsSync(),
      ].every((e) => e);

  /// Check whether all directories exist asynchronously
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        _access.tiles.exists(),
        _access.stats.exists(),
        _access.metadata.exists(),
      ]))
          .every((e) => e);

  /// Create all of the directories synchronously
  void create() {
    _access.tiles.createSync(recursive: true);
    _access.stats.createSync(recursive: true);
    _access.metadata.createSync(recursive: true);
  }

  /// Create all of the directories asynchronously
  Future<void> createAsync() async {
    final List<Future<Directory>> jobs = [
      _access.tiles.create(recursive: true),
      _access.stats.create(recursive: true),
      _access.metadata.create(recursive: true),
    ];
    await Future.wait(jobs);
  }

  /// Delete all of the directories synchronously
  ///
  /// This will remove all traces of this store from the user's device. Use with caution!
  void delete() => _access.real.deleteSync(recursive: true);

  /// Delete all of the directories asynchronously
  ///
  /// This will remove all traces of this store from the user's device. Use with caution!
  Future<void> deleteAsync() => _access.real.delete(recursive: true);

  /// Resets this store synchronously
  ///
  /// Deletes and recreates the [StoreAccess.tiles] directory, and invalidates any cached statistics ([StoreStats.invalidateCachedStatisticsAsync]). Therefore, custom metadata ([StoreMetadata]) is not deleted.
  ///
  /// For a full reset, manually [delete] then [create] the store.
  void reset() {
    _access.tiles.delete(recursive: true);
    _access.tiles.create();
    _storeDirectory.stats.invalidateCachedStatistics(null);
  }

  /// Resets this store synchronously
  ///
  /// Deletes and recreates the [StoreAccess.tiles] directory, and invalidates any cached statistics ([StoreStats.invalidateCachedStatisticsAsync]). Therefore, custom metadata ([StoreMetadata]) is not deleted.
  ///
  /// For a full reset, manually [deleteAsync] then [createAsync] the store.
  Future<void> resetAsync() async {
    await _access.tiles.delete(recursive: true);
    await _access.tiles.create();
    await _storeDirectory.stats.invalidateCachedStatisticsAsync(null);
  }

  /// Rename the store directory synchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  StoreDirectory rename(String storeName) {
    final String safe = FMTCSafeFilesystemString.sanitiser(
      inputString: storeName,
      throwIfInvalid: true,
    );

    _access.real.renameSync(
      p.joinAll([_storeDirectory.rootDirectory.access.real.path, safe]),
    );

    return _storeDirectory.copyWith(storeName: safe);
  }

  /// Rename the store directory asynchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  Future<StoreDirectory> renameAsync(String storeName) async {
    final String safe = FMTCSafeFilesystemString.sanitiser(
      inputString: storeName,
      throwIfInvalid: true,
    );

    await _access.real.rename(
      p.joinAll([_storeDirectory.rootDirectory.access.stores.path, safe]),
    );

    return _storeDirectory.copyWith(storeName: safe);
  }
}
