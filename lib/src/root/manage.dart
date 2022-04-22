import 'dart:io';

import 'access.dart';
import 'directory.dart';

/// Manages a [RootDirectory]'s representation on the filesystem, such as creation and deletion
class RootManagement {
  /// Manages a [RootDirectory]'s representation on the filesystem, such as creation and deletion
  RootManagement(RootDirectory _rootDirectory)
      : _access = RootAccess(_rootDirectory);

  /// Shorthand for [RootDirectory.access], used commonly throughout
  final RootAccess _access;

  /// Create all of the directories synchronously
  void create() {
    _access.real.createSync();
    _access.stores.createSync();
    _access.stats.createSync();
    _access.metadata.createSync();
  }

  /// Create all of the directories asynchronously
  Future<void> createAsync() async {
    final List<Future<Directory>> jobs = [
      _access.real.create(),
      _access.stores.create(),
      _access.stats.create(),
      _access.metadata.create(),
    ];
    await Future.wait(jobs);
  }

  /// Delete all of the directories synchronously
  ///
  /// This will remove all traces of this root from the user's device. Use with caution!
  void delete() => _access.real.deleteSync(recursive: true);

  /// Delete all of the directories asynchronously
  ///
  /// This will remove all traces of this root from the user's device. Use with caution!
  Future<void> deleteAsync() => _access.real.delete(recursive: true);

  /// Empty/reset all of the directories synchronously
  ///
  /// This internally calls [delete] then [create] to achieve the same effect.
  void reset() {
    delete();
    create();
  }

  /// Empty/reset all of the directories asynchronously
  ///
  /// This internally calls [deleteAsync] then [createAsync] to achieve the same effect.
  Future<void> resetAsync() async {
    await deleteAsync();
    await createAsync();
  }
}
