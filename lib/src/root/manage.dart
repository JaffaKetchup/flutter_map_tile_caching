// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'access.dart';
import 'directory.dart';

/// Manages a [RootDirectory]'s representation on the filesystem, such as creation and deletion
class RootManagement {
  /// Manages a [RootDirectory]'s representation on the filesystem, such as creation and deletion
  RootManagement(RootDirectory rootDirectory)
      : _access = RootAccess(rootDirectory);

  /// Shorthand for [RootDirectory.access], used commonly throughout
  final RootAccess _access;

  /// Check whether all directories exist synchronously
  ///
  /// Does not check any sub-stores.
  bool get ready => [
        _access.stores.existsSync(),
        _access.stats.existsSync(),
        _access.recovery.existsSync(),
      ].every((e) => e);

  /// Check whether all directories exist asynchronously
  ///
  /// Does not check any sub-stores.
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        _access.stores.exists(),
        _access.stats.exists(),
        _access.recovery.exists(),
      ]))
          .every((e) => e);

  /// Create all of the directories synchronously
  void create() {
    _access.stores.createSync(recursive: true);
    _access.stats.createSync(recursive: true);
    _access.recovery.createSync(recursive: true);
  }

  /// Create all of the directories asynchronously
  Future<void> createAsync() => Future.wait([
        _access.stores.create(recursive: true),
        _access.stats.create(recursive: true),
        _access.recovery.create(recursive: true),
      ]);

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
