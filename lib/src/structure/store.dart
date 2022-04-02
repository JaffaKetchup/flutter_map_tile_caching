import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../internal/exts.dart';
import '../misc/validate.dart';
import '../storage_managers/storage_manager.dart';
import 'root.dart';

/// Every subfolder of [StoreDirectory] will have a purpose, defined here
@internal
enum PurposeDirectory {
  tiles,
  metadata,
  stats,
}

/// Manages the basic structure of a store (aka. 'cache store')
///
/// A store is identified by it's store name (creating a [storeDirectory]), and resides within the [rootDirectory]. Each store contains a sub-directory for map tile storage, and another for metadata/miscellaneous storage.
///
/// Statistics and more advanced management of stores is provided in [MapCachingManager].
class StoreDirectory {
  //! PROPERTIES & CONSTRUCTOR !//

  /// The container for all files used within this library
  final RootDirectory rootDirectory;

  /// The real directory beneath which [purposeDirectories] reside
  late final Directory storeDirectory;

  /// The user-friendly name of the store directory
  final String name;

  /// Contains [Directory]s which purpose are dictated by their associated [PurposeDirectory] key
  Map<PurposeDirectory, Directory> get purposeDirectories => {
        PurposeDirectory.tiles: storeDirectory >> 'tiles',
        PurposeDirectory.metadata: storeDirectory >> 'metadata',
        PurposeDirectory.stats: storeDirectory >> 'stats',
      };

  /// Create a [StoreDirectory] set based on a [RootDirectory] and a valid/safe store name
  ///
  /// [storeName] is validated to ensure it is safe to use. See [safeFilesystemString] for more documentation. Unsafe names will throw an error, so it is recommended to validate the name before construction, using the aforementioned method, or by [validateFilesystemString] for input fields.
  ///
  /// Construction via this method automatically calls [create] before returning (by default), so the caching directories will exist unless deleted using [delete]. Disable this initialisation by setting [autoCreate] to `false`.
  StoreDirectory({
    required this.rootDirectory,
    required this.name,
    bool autoCreate = true,
  }) {
    storeDirectory = rootDirectory.rootDirectory >>
        (safeFilesystemString(inputString: name, throwIfInvalid: true));

    if (autoCreate) create();
  }

  //! READY CHECKERS !//

  /// Check whether all directories exist synchronously
  bool get ready =>
      purposeDirectories.values.map((e) => e.existsSync()).every((e) => e);

  /// Check whether all directories exist asynchronously
  Future<bool> get readyAsync async =>
      (await Future.wait(purposeDirectories.values.map((e) => e.exists())))
          .every((e) => e);

  //! MANAGERS !//

  /// Create all of the directories synchronously
  void create() {
    storeDirectory.createSync();
    purposeDirectories.values.map((e) => e.createSync());
  }

  /// Create all of the directories asynchronously
  Future<void> createAsync() async =>
      await Future.wait(purposeDirectories.values.map((e) => e.create()));

  /// Delete all of the directories synchronously
  ///
  /// This will remove all traces of this library from the user's device. Use with caution!
  void delete() => storeDirectory.deleteSync(recursive: true);

  /// Delete all of the directories asynchronously
  ///
  /// This will remove all traces of this library from the user's device. Use with caution!
  Future<void> deleteAsync() => storeDirectory.delete(recursive: true);

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

    storeDirectory.renameSync(p.joinAll([rootDirectory.path, safe]));

    return copyWith(storeName: safe);
  }

  /// Rename the store directory asynchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  Future<StoreDirectory> renameAsync(String storeName) async {
    final String safe =
        safeFilesystemString(inputString: storeName, throwIfInvalid: true);

    await storeDirectory.rename(p.joinAll([rootDirectory.path, safe]));

    return copyWith(storeName: safe);
  }

  //! SAFETY !//

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

  //! MISC !//

  StoreDirectory copyWith({
    RootDirectory? rootDir,
    String? storeName,
  }) {
    return StoreDirectory(
      rootDirectory: rootDir ?? rootDirectory,
      name: storeName ?? name,
    );
  }

  @override
  String toString() {
    return 'StoreDirectory(rootDirectory: $rootDirectory, storeDirectory: $storeDirectory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoreDirectory &&
        other.rootDirectory == rootDirectory &&
        other.storeDirectory == storeDirectory;
  }

  @override
  int get hashCode {
    return rootDirectory.hashCode ^ storeDirectory.hashCode;
  }
}
