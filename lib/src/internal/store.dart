import 'dart:io';

import 'package:path/path.dart' as p;

import '../misc/validate.dart';
import '../structure/root.dart';
import 'exts.dart';

/// Access point to a store
///
/// Contains access to:
/// * Statistics
/// * Management
/// * Low-Level Access (advanced)
///
/// A store is identified by it's validated store name, and represents a directory that resides within a [RootDirectory]. Each store contains multiple sub-directories.
class StoreDirectory {
  /// The container for all files used within this library
  final RootDirectory _rootDirectory;

  /// The user-friendly name of the store directory
  final String storeName;

  /// Creates an access point to a store
  ///
  /// Contains access to:
  /// * Statistics
  /// * Management
  /// * Low-Level Access (advanced)
  ///
  /// A store is identified by it's validated store name (see [safeFilesystemString] - an error is throw if the name is invalid), and represents a directory that resides within a [RootDirectory]. Each store contains multiple sub-directories.
  ///
  /// Construction via this method automatically calls [_StoreManagement.create] before returning (by default), so the caching directories will exist unless deleted using [_StoreManagement.delete]. Disable this initialisation by setting [autoCreate] to `false`.
  StoreDirectory(
    this._rootDirectory,
    this.storeName, {
    bool autoCreate = true,
  }) {
    if (autoCreate) manage.create();
  }

  /// Check whether all directories exist synchronously
  bool get ready => [
        access.tiles.existsSync(),
        access.stats.existsSync(),
        access.metadata.existsSync(),
      ].every((e) => e);

  /// Check whether all directories exist asynchronously
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        access.tiles.exists(),
        access.stats.exists(),
        access.metadata.exists(),
      ]))
          .every((e) => e);

  /// Get direct filesystem access paths
  ///
  /// This should only be used in special cases, when modifying the store manually for example.
  _StoreAccess get access => _StoreAccess(this);

  /// Manage the store's representation on the filesystem
  ///
  /// Provides access to methods to:
  ///  * Create
  ///  * Delete
  ///  * Rename
  ///  * Reset
  _StoreManagement get manage => _StoreManagement(this);

  /// Public validator (semi-exposing internal [safeFilesystemString]) used to ensure strings are safe for storage in the filesystem
  ///
  /// This is useful to validate user-facing input for store names (such as in `TextFormField`s), and ensure that they:
  ///  - comply with limitations of the filesystem
  ///  - don't cause problems where sanitised input causes duplication
  ///
  /// The first cannot be guaranteed 100%, as control characters (except NUL) and potential reserved names are not checked; but it is better than nothing.
  ///
  /// To understand the latter, imagine your user inputs two store names, 'a\*b\*c' and 'a:b:c'. If this were to just sanitise the string, they would end up with the same name 'a_b_c', as '*' and ':' are invalid characters. Therefore, the user may expect two stores but only get one. Likewise, the user would see a different name to the one they inputted.
  ///
  /// The internal method mentioned above, however can be used in two modes: sanitise or throw. Sanitise mode is used where duplications are impossible and the end-user should never see the exact name: such as for the storage of tiles as images in the filesystem. Throw mode is used in the constructors of [StorageCachingTileProvider] and [MapCachingManager], and prevents invalid input for the reasons mentioned above.
  ///
  /// Therefore, to prevent unexpected errors on construction, it is recommended to use this as a validator for user inputted store names: it can be put right in the `validator` property!
  ///
  /// A `null` output means the string is valid, otherwise appropriate error text is outputted (in English).
  static String? validateFilesystemString(String? storeName) {
    try {
      safeFilesystemString(inputString: storeName ?? '', throwIfInvalid: true);
      return null;
    } catch (e) {
      return e as String;
    }
  }

  StoreDirectory copyWith({
    RootDirectory? rootDirectory,
    String? storeName,
  }) =>
      StoreDirectory(
        rootDirectory ?? _rootDirectory,
        storeName ?? this.storeName,
      );

  @override
  String toString() {
    return 'StoreDirectory(rootDirectory: $_rootDirectory, storeName: $storeName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoreDirectory &&
        other._rootDirectory == _rootDirectory &&
        other.storeName == storeName;
  }

  @override
  int get hashCode {
    return _rootDirectory.hashCode ^ storeName.hashCode;
  }
}

/// Provides direct filesystem access paths to a [StoreDirectory] - use with caution
class _StoreAccess {
  /// The store directory to provide access paths to
  final StoreDirectory _storeDirectory;

  /// Provides direct filesystem access paths to a [StoreDirectory] - use with caution
  _StoreAccess(this._storeDirectory) {
    real = _storeDirectory._rootDirectory.rootDirectory >>
        (safeFilesystemString(
            inputString: _storeDirectory.storeName, throwIfInvalid: true));

    tiles = real >> 'tiles';
    stats = real >> 'stats';
    metadata = real >> 'metadata';
  }

  /// The real parent [Directory] of the [StoreDirectory] - directory name is equal to store's name
  late final Directory real;

  /// The sub[Directory] used to store map tiles
  late final Directory tiles;

  /// The sub[Directory] used to store cached statistics
  late final Directory stats;

  /// The sub[Directory] used to store any miscellaneous metadata
  late final Directory metadata;
}

/// Manages stores' representation on the filesystem, such as creation and deletion
class _StoreManagement {
  /// The store directory to manage
  final StoreDirectory _storeDirectory;

  /// Manages stores' representation on the filesystem, such as creation and deletion
  _StoreManagement(this._storeDirectory)
      : _access = _StoreAccess(_storeDirectory);

  /// Shorthand for [StoreDirectory.access], used commonly throughout
  final _StoreAccess _access;

  /// Create all of the directories synchronously
  void create() {
    _access.real.createSync();
    _access.tiles.createSync();
    _access.stats.createSync();
    _access.metadata.createSync();
  }

  /// Create all of the directories asynchronously
  Future<void> createAsync() async {
    final List<Future<Directory>> jobs = [
      _access.real.create(),
      _access.tiles.create(),
      _access.stats.create(),
      _access.metadata.create(),
    ];
    await Future.wait(jobs);
  }

  /// Delete all of the directories synchronously
  ///
  /// This will remove all traces of this library from the user's device. Use with caution!
  void delete() => _access.real.deleteSync(recursive: true);

  /// Delete all of the directories asynchronously
  ///
  /// This will remove all traces of this library from the user's device. Use with caution!
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

  /// Rename the store directory synchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  StoreDirectory rename(String storeName) {
    final String safe =
        safeFilesystemString(inputString: storeName, throwIfInvalid: true);

    _access.real
        .renameSync(p.joinAll([_storeDirectory._rootDirectory.path, safe]));

    return _storeDirectory.copyWith(storeName: safe);
  }

  /// Rename the store directory asynchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  Future<StoreDirectory> renameAsync(String storeName) async {
    final String safe =
        safeFilesystemString(inputString: storeName, throwIfInvalid: true);

    await _access.real
        .rename(p.joinAll([_storeDirectory._rootDirectory.path, safe]));

    return _storeDirectory.copyWith(storeName: safe);
  }
}
