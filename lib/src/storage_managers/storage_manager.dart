import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p show joinAll, split;
import 'package:path_provider/path_provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../main.dart';
import '../misc/validate.dart';

/// Manages caching statistics and general running (synchronously or asynchronously)
///
/// See [StorageCachingTileProvider] for object that manages browse caching and bulk downloading
///
/// On initialisation, automatically creates the cache & store, if applicable, if they do not exist. Store will not be created if not specified.
///
/// All operations have two versions (synchronous and asynchronous). The first provides decreases code complexity at the expense of worse performance; the latter is the opposite.
///
/// Functions may throw errors if requirements aren't met: for example, [allStoresNames] requires the [parentDirectory] to exist, whilst [storeName] requires [storeDirectory] to exist, and therefore [storeName] not to be `null`.
class MapCachingManager {
  /// Container directory for stores (previously `parentDirectory`)
  ///
  /// Use [normalCache] wherever possible, or [temporaryCache] alternatively (see documentation). To use those [Future] values, you may need to use the `async` `await` pattern. If creating a path manually, be sure it's the correct format, use the 'package:path' library if needed.
  ///
  /// Required.
  final Directory parentDirectory;

  /// Name of a store, or `null` if using this to only query about the overall [parentDirectory]
  ///
  /// Is validated through [safeFilesystemString] : an error will be thrown if the store name is given and invalid, see [validateStoreNameString] to validate names safely before construction.
  final String? storeName;

  /// Directory containing all cached tiles and metadata for the store
  ///
  /// Automatically generated from [parentDirectory] & [storeName], if applicable.
  final Directory? storeDirectory;

  /// Manages caching statistics and general running (synchronously or asynchronously)
  ///
  /// See [StorageCachingTileProvider] for object that manages browse caching and bulk downloading
  ///
  /// On initialisation, automatically creates the cache & store, if applicable, if they do not exist. Store will not be created if not specified.
  ///
  /// All operations have two versions (synchronous and asynchronous). The first provides decreases code complexity at the expense of worse performance; the latter is the opposite.
  ///
  /// Functions may throw errors if requirements aren't met: for example, [allStoresNames] requires the [parentDirectory] to exist, whilst [storeName] requires [storeDirectory] to exist, and therefore [storeName] not to be `null`.
  MapCachingManager(
    this.parentDirectory, [
    this.storeName,
  ]) : storeDirectory = storeName == null
            ? null
            : Directory(p.joinAll([
                parentDirectory.absolute.path,
                safeFilesystemString(
                    inputString: storeName, throwIfInvalid: true),
              ])) {
    parentDirectory.createSync(recursive: true);
    storeDirectory?.createSync(recursive: true);
  }

  /// Construct [MapCachingManager] inside an isolate to avoid blocking main thread - any filesystem operation will be asynchronous.
  ///
  /// For other information, see the standard synchronous constructor [MapCachingManager].
  static Future<MapCachingManager> async(
    Directory cacheDirectory, [
    String? storeName,
  ]) async =>
      await compute((_) => MapCachingManager(cacheDirectory, storeName), {});

  /// Check if the store exists
  ///
  /// Returns `true` if it does, `false` if only the [parentDirectory] exists, `null` if neither exist.
  bool? get exists {
    try {
      _storeRequired;
    } catch (e) {
      return null;
    }

    try {
      _cacheRequired;
    } catch (e) {
      return false;
    }

    return true;
  }

  //! MANAGEMENT !//

  /// Deprecated. To create the store, reinitialize the [MapCachingManager], and it will be created automatically.
  @Deprecated(
      'To create the store, reinitialize the `MapCachingManager`, and it will be created automatically')
  void createStore() => storeDirectory?.createSync(recursive: true);

  /// Delete a store
  ///
  /// To only empty the store, see [emptyStore].
  void deleteStore() {
    _storeRequired;
    storeDirectory!.deleteSync(recursive: true);
  }

  /// Empty a store (delete all contained tiles and metadata)
  void emptyStore() {
    _storeRequired;

    for (FileSystemEntity e in storeDirectory!.listSync(recursive: true)) {
      e.deleteSync();
    }
  }

  /// Delete all stores
  void deleteAllStores() {
    _cacheRequired;
    parentDirectory.deleteSync(recursive: true);
  }

  /// Rename the current store
  ///
  /// The old [MapCachingManager] will still retain it's link to the old store, so always use the new returned value instead: returns a new [MapCachingManager] after a successful renaming operation.
  ///
  /// An error will be thrown if the new store name is invalid, see [validateStoreNameString] to validate names safely beforehand.
  MapCachingManager renameStore(String newName) {
    _storeRequired;

    final String safeNewName =
        safeFilesystemString(inputString: newName, throwIfInvalid: true);
    storeDirectory!
        .renameSync(p.joinAll([parentDirectory.absolute.path, safeNewName]));

    return MapCachingManager(parentDirectory, safeNewName);
  }

  //! WATCHERS !//

  /// Watch for changes in the current cache
  ///
  /// By default, [recursive] is set to `false`, meaning only top level changes (those to do with each store) will be caught. Enable recursivity to also include events from [watchStoreChanges].
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Control which changes are caught through the [fileSystemEvents] property, which takes [FileSystemEvent]s, and by default ignores modifications (ie. renaming).
  ///
  /// Enable debouncing to prevent unnecessary rebuilding for tiny changes in detail using [enableDebounce]. Optionally change the [debounceDuration] from 200ms to 'fire' more or less frequently.
  ///
  /// Debouncing example (dash roughly represents [debounceDuration]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  Stream<void> watchCacheChanges(
    bool enableDebounce, {
    bool recursive = false,
    Duration debounceDuration = const Duration(milliseconds: 200),
    int fileSystemEvents = ~FileSystemEvent.modify,
  }) {
    _cacheRequired;

    final Stream<void> stream = parentDirectory
        .watch(events: fileSystemEvents, recursive: recursive)
        .map((_) => null);

    return enableDebounce ? stream.debounce(debounceDuration) : stream;
  }

  /// Watch for changes in the current store
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Control which changes are caught through the [fileSystemEvents] property, which takes [FileSystemEvent]s, and by default ignores modifications (ie. renaming).
  ///
  /// Enable debouncing to prevent unnecessary rebuilding for tiny changes in detail using [enableDebounce]. Optionally change the [debounceDuration] from 200ms to 'fire' more or less frequently.
  ///
  /// Debouncing example (dash roughly represents [debounceDuration]):
  /// ```dart
  /// input:  1-2-3---4---5-6-|
  /// output: ------3---4-----6|
  /// ```
  Stream<void> watchStoreChanges(
    bool enableDebounce, {
    Duration debounceDuration = const Duration(milliseconds: 200),
    int fileSystemEvents = ~FileSystemEvent.modify,
  }) {
    _storeRequired;

    final Stream<void> stream =
        storeDirectory!.watch(events: fileSystemEvents).map((event) => null);
    return enableDebounce ? stream.debounce(debounceDuration) : stream;
  }

  //! STAT GETTERS !//

  /// Retrieve a list of all names of existing stores
  List<String> get allStoresNames {
    _cacheRequired;

    List<String> returnable = [];
    for (FileSystemEntity e
        in parentDirectory.listSync(followLinks: false, recursive: false)) {
      returnable.add(p.split(e.absolute.path).last);
    }

    return returnable;
  }

  /// Retrieve the size of a store in kibibytes (KiB)
  double get storeSize {
    _storeRequired;

    int totalSize = 0;
    for (FileSystemEntity e in storeDirectory!.listSync(recursive: true)) {
      totalSize += e is File ? e.lengthSync() : 0;
    }

    return totalSize / 1024;
  }

  /// Retrieve the size of all stores in kibibytes (KiB)
  double get allStoresSizes {
    _cacheRequired;

    double returnable = 0;
    for (String name in allStoresNames) {
      returnable += MapCachingManager(parentDirectory, name).storeSize;
    }

    return returnable;
  }

  /// Retrieve the number of stored tiles in a store
  int get storeLength {
    _storeRequired;
    return storeDirectory!.listSync().length;
  }

  /// Retrieve the number of stored tiles in all stores
  int get allStoresLengths {
    _cacheRequired;

    int returnable = 0;
    for (String name in allStoresNames) {
      returnable += MapCachingManager(parentDirectory, name).storeLength;
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
  /// Returns `null` if there are no cached tiles.
  Image? coverImage({
    required bool random,
    int? maxRange,
    double? size,
  }) {
    _storeRequired;

    final int storeLen = storeLength;
    if (storeLen == 0) return null;

    if (!random && maxRange != null) {
      throw ArgumentError(
          'If not in random mode, `maxRange` must be left as `null`');
    }
    if (maxRange != null && (maxRange < 1 || maxRange > storeLen)) {
      throw ArgumentError(
          'If specified, `maxRange` must be more than or equal to 1 and less than or equal to `storeLength`');
    }

    final int? randInt = !random ? null : Random().nextInt(maxRange!);
    int i = 0;

    for (FileSystemEntity evt in storeDirectory!.listSync()) {
      if (i == (randInt ?? 0)) {
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

  //! CACHE DIRECTORY GETTERS !//

  /// Get the application's documents directory
  ///
  /// Caching in here will show caches under the App Storage - instead of under App Cache - in Settings, and therefore the OS or other apps cannot clear the cache without telling the user.
  ///
  /// In some cases, even clearing App Storage won't clear this, depending on the device vendor. An uninstall will always should the storage properly.
  static Future<Directory> get normalCache async => Directory(
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
  static Future<Directory> get temporaryCache async => Directory(
        p.joinAll([(await getTemporaryDirectory()).absolute.path, 'mapCache']),
      );

  //! PRIVATE THROWERS !//

  /// Functions that require [storeDirectory] or [storeName] should call to ensure they are usable
  ///
  /// Superset of [_cacheRequired].
  void get _storeRequired {
    if (storeDirectory == null ||
        !storeDirectory!.existsSync() ||
        storeName == null) {
      throw '`storeName` is required, and `storeDirectory` must exist, to use this function';
    }
  }

  /// Functions that require [parentDirectory] should call to ensure they are usable
  ///
  /// Subset of [_storeRequired].
  void get _cacheRequired {
    if (!parentDirectory.existsSync()) {
      throw '`cacheDirectory` must exist to use this function';
    }
  }

  //! GENERAL OBJECT STUFF !//

  @override
  String toString() =>
      'MapCachingManager(storeName: $storeName, cacheDirectory: $parentDirectory, storeDirectory: $storeDirectory)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapCachingManager &&
        other.storeName == storeName &&
        other.parentDirectory == parentDirectory &&
        other.storeDirectory == storeDirectory;
  }

  @override
  int get hashCode =>
      storeName.hashCode ^ parentDirectory.hashCode ^ storeDirectory.hashCode;

  MapCachingManager copyWith({
    Directory? parentDirectory,
    String? storeName,
  }) =>
      MapCachingManager(
        parentDirectory ?? this.parentDirectory,
        storeName ?? this.storeName,
      );
}
