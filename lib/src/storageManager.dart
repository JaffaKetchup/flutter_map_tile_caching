import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p show joinAll, split;

/// Handles caching for tiles
///
/// Used internally for downloading regions, another library is depended on for 'browse caching'.
class MapCachingManager {
  /// The directory to place cache stores into
  ///
  /// Use the same directory used in `StorageCachingTileProvider` (`await MapCachingManager.normalDirectory` recommended). Required.
  final Directory parentDirectory;

  /// The name of a store. Defaults to 'mainStore'.
  final String storeName;

  /// The correctly joined `parentDirectory` and `storeName` at time of initialization.
  final String _joinedBasePath;

  /// Create an instance to handle caching for tiles
  ///
  /// Used internally for downloading regions, another library is depended on for 'browse caching'.
  MapCachingManager(this.parentDirectory, [this.storeName = 'mainStore'])
      : _joinedBasePath = p.joinAll([parentDirectory.absolute.path, storeName]);

  /// Explicitly create the store - only use if necessary
  @visibleForTesting
  void createStore() => Directory(_joinedBasePath).createSync(recursive: true);

  /// Delete a cache store
  void deleteStore() {
    if (Directory(_joinedBasePath).existsSync())
      Directory(_joinedBasePath).deleteSync(recursive: true);
  }

  /// Delete all cache stores
  void deleteAllStores() {
    if (Directory(parentDirectory.absolute.path).existsSync())
      Directory(parentDirectory.absolute.path).deleteSync(recursive: true);
  }

  /// Rename the current cache store to a new name
  ///
  /// Returns the new `MapCachingManager` after a successful renaming operation or `null` if the cache does not exist.
  MapCachingManager? renameStore(String newName) {
    if (!Directory(parentDirectory.absolute.path).existsSync()) return null;
    Directory(_joinedBasePath)
        .renameSync(p.joinAll([parentDirectory.absolute.path, newName]));
    return MapCachingManager(parentDirectory, newName);
  }

  /// Retrieve a list of all names of existing cache stores
  ///
  /// Returns `null` if the cache does not exist.
  List<String>? get allStoresNames {
    if (!Directory(parentDirectory.absolute.path).existsSync()) return null;
    List<String> returnable = [];
    Directory(parentDirectory.absolute.path)
        .listSync(followLinks: false, recursive: false)
        .forEach((dir) => returnable.add(p.split(dir.absolute.path).last));
    return returnable;
  }

  /// Retrieve the size (in bytes) of a cache store
  ///
  /// Use `.bytesToMegabytes` on the output to get the real number of megabytes
  ///
  /// Returns `null` if the store does not exist.
  int? get storeSize {
    if (!Directory(_joinedBasePath).existsSync()) return null;
    return Directory(_joinedBasePath).statSync().size;
  }

  /// Retrieve the size (in bytes) of all cache stores
  ///
  /// Use `.bytesToMegabytes` on the output to get the real number of megabytes.
  ///
  /// Returns `null` if the cache does not exist.
  int? get allStoresSizes {
    if (!Directory(parentDirectory.absolute.path).existsSync()) return null;
    int returnable = 0;
    allStoresNames!.forEach((storeName) => returnable +=
        MapCachingManager(parentDirectory, storeName).storeSize ?? 0);
    return returnable;
  }

  /// Retrieve the number of stored tiles in a cache store
  ///
  /// Returns `null` if the store does not exist.
  int? get storeLength {
    if (!Directory(_joinedBasePath).existsSync()) return null;
    return Directory(_joinedBasePath).listSync().length;
  }

  /// Retrieve the number of stored tiles in all cache stores
  ///
  /// Returns `null` if the cache does not exist.
  int? get allStoresLengths {
    if (!Directory(parentDirectory.absolute.path).existsSync()) return null;
    int totalLength = 0;
    allStoresNames!.forEach((name) {
      totalLength += Directory(p.joinAll([parentDirectory.absolute.path, name]))
          .listSync(recursive: true)
          .length;
    });
    return totalLength;
  }

  /// Get the application's documents directory
  ///
  /// Caching in here will show caches under the App Storage - instead of under App Cache - in Settings, and therefore the OS or other apps cannot clear the cache without telling the user.
  static Future<Directory> get normalDirectory async {
    return Directory(p.joinAll([
      (await getApplicationDocumentsDirectory()).absolute.path,
      'mapCache'
    ]));
  }

  /// Get the temporary storage directory
  ///
  /// Caching in here will show caches under the App Cache - instead of App Storage - in Settings. Therefore the OS can clear cached tiles at any time without telling the user.
  ///
  /// For this reason, it is not recommended to use this store. Use `normalDirectory` by default instead.
  static Future<Directory> get temporaryDirectory async {
    return Directory(
        p.joinAll([(await getTemporaryDirectory()).absolute.path, 'mapCache']));
  }
}
