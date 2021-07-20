import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p show joinAll;
import 'exts.dart';

/// Handles caching for tiles
///
/// Used internally for downloading regions, another library is depended on for 'browse caching'.
class MapCachingManager {
  /// The directory to place cache stores into
  ///
  /// Use the same directory used in `StorageCachingTileProvider` (`await MapCachingManager.normalDirectory` recommended). Required.
  final Directory parentDirectory;

  /// The name of a store. Defaults to 'mainCache'.
  final String storeName;

  /// The correctly joined `parentDirectory` and `storeName` at time of initialization.
  final String _joinedBasePath;

  /// Create an instance to handle caching for tiles
  ///
  /// Used internally for downloading regions, another library is depended on for 'browse caching'.
  MapCachingManager(this.parentDirectory, [this.storeName = 'mainCache'])
      : _joinedBasePath = p.joinAll([parentDirectory.path, storeName]);

  /// Delete a cache store
  void deleteStore() {
    if (Directory(_joinedBasePath).existsSync())
      Directory(_joinedBasePath).deleteSync(recursive: true);
  }

  /// Delete all cache stores
  void deleteAllStores() {
    if (Directory(parentDirectory.path).existsSync())
      Directory(parentDirectory.path).deleteSync(recursive: true);
  }

  /// Retrieve a list of all names of existing cache stores
  ///
  /// Returns `null` if the cache does not exist.
  List<String>? get allStoresNames {
    if (!Directory(parentDirectory.path).existsSync()) return null;
    List<String> returnable = [];
    for (FileSystemEntity dir in Directory(parentDirectory.path)
        .listSync(followLinks: false, recursive: false)) {
      returnable.add(dir.path.split('/')[dir.path.split('/').length - 1]);
    }
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
  int? get allStoresSize {
    if (!Directory(parentDirectory.path).existsSync()) return null;
    int returnable = 0;
    if (allStoresNames != null)
      allStoresNames!.forEach((storeName) {
        returnable +=
            MapCachingManager(parentDirectory, storeName).storeSize ?? 0;
      });
    else
      return 0;
    return returnable;
  }

  /// Retrieve the number of stored tiles in a cache store
  ///
  /// Returns `null` if the store does not exist.
  int? get storeLength {
    if (!Directory(_joinedBasePath).existsSync()) return null;
    return Directory(_joinedBasePath).listSync().length;
  }

  /// Retrieve the (approximate) number of stored tiles in all cache stores
  ///
  /// Returns `null` if the cache does not exist.
  int? get allStoresLength {
    if (!Directory(parentDirectory.path).existsSync()) return null;
    return (Directory(parentDirectory.path).listSync(recursive: true).length) -
        ((allStoresNames?.length ?? 0) * 2);
  }

  /// Get the application's documents directory
  ///
  /// Caching in here will show caches under the App Storage - instead of under App Cache - in Settings, and therefore the OS or other apps cannot clear the cache without telling the user.
  static Future<Directory> get normalDirectory async {
    return Directory(p.joinAll(
        [(await getApplicationDocumentsDirectory()).path, 'mapCache']));
  }

  /// Get the temporary storage directory
  ///
  /// Caching in here will show caches under the App Cache - instead of App Storage - in Settings. Therefore the OS can clear cached tiles at any time without telling the user.
  ///
  /// For this reason, it is not recommended to use this store. Use `normalDirectory` by default instead.
  static Future<Directory> get temporaryDirectory async {
    return Directory(
        p.joinAll([(await getTemporaryDirectory()).path, 'mapCache']));
  }

  /// Returns the current working store's path, store's size, and all stores size, as a human-friendly 3-line string
  @override
  String toString() {
    final String path = p.joinAll([parentDirectory.path, storeName]);
    return '$path\nStore size: ${(storeSize ?? 0).bytesToMegabytes}MB\nAll stores size: ${(allStoresSize ?? 0).bytesToMegabytes}MB';
  }
}
