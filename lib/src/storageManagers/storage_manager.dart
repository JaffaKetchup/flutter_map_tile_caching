import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p show joinAll, split;
import 'package:path_provider/path_provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../misc/typedefs.dart';
import '../misc/validate.dart';

/// Handles caching for tiles (synchronously or asynchronously)
///
/// On initialisation, automatically creates the cache store if it does not exist.
///
/// All operations have two versions (synchronous and asynchronous). The first provides decreases code complexity at the expense of worse performance; the latter is the opposite.
class MapCachingManager {
  /// The directory to place cache stores into
  ///
  /// Use [normalCache] wherever possible, or [temporaryCache] alternatively (see documentation). To use those `Future` values, you may need to use the `async` `await` pattern. If creating a path manually, be sure it's the correct format, use the `path` library if needed.
  ///
  /// Required.
  final CacheDirectory parentDirectory;

  /// The name of a cache store. Defaults to 'mainStore'.
  final String storeName;

  /// Automatically generated. Contains the absolute path to the cache store after initialization.
  final String storePath;

  /// Create an instance to handle caching for tiles
  ///
  /// On initialization, automatically creates the cache store if it does not exist.
  ///
  /// Please note that most internal file handling is performed synchronusly to make this library easier to use. This comes at the cost of performance: keep usage of stat checking to a minimum.
  ///
  /// Used internally for downloading regions, another library is depended on for 'browse caching'.
  MapCachingManager(this.parentDirectory, [this.storeName = 'mainStore'])
      : storePath = p.joinAll([
          parentDirectory.absolute.path,
          safeFilesystemString(inputString: storeName, throwIfInvalid: true),
        ]) {
    Directory(storePath).createSync(recursive: true);
  }

  /// Check if the cache store exists
  ///
  /// Returns `true` if it does, `false` if only the [parentDirectory] exists, `null` if neither exist.
  bool? get exists => Directory(storePath).existsSync()
      ? true
      : Directory(parentDirectory.absolute.path).existsSync()
          ? false
          : null;

  /// Deprecated. To create the store, reinitialize the [MapCachingManager], and it will be created automatically.
  @Deprecated(
      'To create the store, reinitialize the `MapCachingManager`, and it will be created automatically')
  void createStore() => Directory(storePath).createSync(recursive: true);

  /// Delete a cache store
  void deleteStore() {
    if (exists ?? false) Directory(storePath).deleteSync(recursive: true);
  }

  /// Empty a cache store (delete all contained tiles)
  void emptyStore() {
    if (exists ?? false) {
      Directory(storePath).listSync(recursive: true).forEach((element) {
        element.deleteSync();
      });
    }
  }

  /// Delete all cache stores
  void deleteAllStores() {
    if (exists != null) {
      Directory(parentDirectory.absolute.path).deleteSync(recursive: true);
    }
  }

  /// Rename the current cache store to a new name
  ///
  /// The old [MapCachingManager] will still retain it's link to the old store, so always use the new returned value instead: returns a new [MapCachingManager] after a successful renaming operation or `null` if the cache does not exist.
  MapCachingManager? renameStore(String newName) {
    if (exists == null) return null;
    Directory(storePath)
        .renameSync(p.joinAll([parentDirectory.absolute.path, newName]));
    return MapCachingManager(parentDirectory, newName);
  }

  /// Watch for changes in the current cache (not recursive, so should not include events from [watchStoreChanges])
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Enable debouncing to prevent unnecessary rebuilding for tiny changes in detail using [enableDebounce]. Optionally change the [debounceDuration] from 200ms to 'fire' more or less frequently.
  ///
  /// Debouncing example (dash represents [debounceDuration]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  ///
  /// Returns `null` if the store does not exist.
  Stream<void>? watchCacheChanges(
    bool enableDebounce, [
    Duration debounceDuration = const Duration(milliseconds: 200),
  ]) {
    if (!(exists ?? false)) return null;

    final Stream<void> stream =
        Directory(parentDirectory.absolute.path).watch().map((event) => null);

    return enableDebounce ? stream.debounce(debounceDuration) : stream;
  }

  /// Watch for changes in the current store
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Enable debouncing to prevent unnecessary rebuilding for tiny changes in detail using [enableDebounce]. Optionally change the [debounceDuration] from 200ms to 'fire' more or less frequently.
  ///
  /// Debouncing example (dash represents [debounceDuration]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  ///
  /// Returns `null` if the store does not exist.
  Stream<void>? watchStoreChanges(
    bool enableDebounce, [
    Duration debounceDuration = const Duration(milliseconds: 200),
  ]) {
    if (!(exists ?? false)) return null;

    final Stream<void> stream =
        Directory(storePath).watch().map((event) => null);

    return enableDebounce ? stream.debounce(debounceDuration) : stream;
  }

  /// Retrieve a list of all names of existing cache stores
  ///
  /// Returns `null` if the cache does not exist.
  List<String>? get allStoresNames {
    if (exists == null) return null;
    List<String> returnable = [];
    Directory(parentDirectory.absolute.path)
        .listSync(followLinks: false, recursive: false)
        .forEach((dir) => returnable.add(p.split(dir.absolute.path).last));
    return returnable;
  }

  /// Retrieve the size of a cache store in kibibytes (KiB)
  ///
  /// Returns `null` if the store does not exist.
  double? get storeSize {
    if (!(exists ?? false)) return null;

    int totalSize = 0;
    Directory(storePath).listSync(recursive: true).forEach(
          (FileSystemEntity e) => totalSize += e is File ? e.lengthSync() : 0,
        );

    return totalSize / 1024;
  }

  /// Retrieve the size of all cache stores in kibibytes (KiB)
  ///
  /// Returns `null` if the cache does not exist.
  double? get allStoresSizes {
    if (exists == null) return null;
    double returnable = 0;
    for (var storeName in allStoresNames!) {
      returnable +=
          MapCachingManager(parentDirectory, storeName).storeSize ?? 0;
    }
    return returnable;
  }

  /// Retrieve the number of stored tiles in a cache store
  ///
  /// Returns `null` if the store does not exist.
  int? get storeLength {
    if (!(exists ?? false)) return null;
    return Directory(storePath).listSync().length;
  }

  /// Retrieve the number of stored tiles in all cache stores
  ///
  /// Returns `null` if the cache does not exist.
  int? get allStoresLengths {
    if (exists == null) return null;
    int returnable = 0;
    for (var name in allStoresNames!) {
      returnable += Directory(p.joinAll([parentDirectory.absolute.path, name]))
          .listSync(recursive: true)
          .length;
    }
    return returnable;
  }

  /// Retrieves a (potentially random) tile from the store and uses it to create a cover [Image]
  ///
  /// [random] controls whether the chosen tile is chosen at random or whether the chosen tile is the 'first' tile in the store. Note that 'first' means alphabetically, not chronologically.
  ///
  /// Using random mode may take a while to generate if the random number is large.
  ///
  /// If using random mode, optionally set [maxRange] to an integer (1 <= [maxRange] <= [storeLength]) to only generate a random number between 0 and the specified number. Useful to reduce waiting times or enforce consistency.
  ///
  /// Returns `null` if the store does not exist or there are no cached tiles.
  Image? coverImage({
    required bool random,
    int? maxRange,
    double? size,
  }) {
    final int? storeLen = storeLength;

    if (!(exists ?? false)) return null;
    if (storeLen == 0) return null;

    assert(
      random ? true : maxRange == null,
      'If not in random mode, `maxRange` must be left as `null`',
    );
    assert(
      (maxRange ?? 1) >= 1 && (maxRange ?? 1) <= storeLen!,
      'If specified, `maxRange` must be more than or equal to 1 and less than or equal to `storeLength`',
    );

    final int randInt =
        random ? Random().nextInt(maxRange ?? (storeLen! + 1)) : -1;

    int i = 0;

    for (FileSystemEntity evt in Directory(storePath).listSync()) {
      if (!random || i == randInt) {
        return Image.file(
          File(evt.absolute.path),
          width: size,
          height: size,
        );
      }
      i++;
    }

    throw FallThroughError();
  }

  /// Get the application's documents directory
  ///
  /// Caching in here will show caches under the App Storage - instead of under App Cache - in Settings, and therefore the OS or other apps cannot clear the cache without telling the user.
  static Future<CacheDirectory> get normalCache async => Directory(
        p.joinAll([
          (await getApplicationDocumentsDirectory()).absolute.path,
          'mapCache'
        ]),
      );

  /// Get the temporary storage directory
  ///
  /// Caching in here will show caches under the App Cache - instead of App Storage - in Settings. Therefore the OS can clear cached tiles at any time without telling the user.
  ///
  /// For this reason, it is not recommended to use this store. Use [normalCache] by default instead.
  static Future<CacheDirectory> get temporaryCache async => Directory(
        p.joinAll([(await getTemporaryDirectory()).absolute.path, 'mapCache']),
      );
}
