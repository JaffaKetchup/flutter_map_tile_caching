import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p show split;
import 'package:stream_transform/stream_transform.dart';

import '../internal/exts.dart';
import '../main.dart';
import '../structure/root.dart';
import '../structure/store.dart';

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
  /// Set of directories, on the cache level
  ///
  /// Use [RootDirectory.normalCache] wherever possible, or [RootDirectory.temporaryCache] alternatively (see documentation on those constructors). To use those [Future] values, you may need to use the `async` `await` pattern. If creating a path manually with [CacheDirectory.custom], be sure it's correct (see documentation).
  late final RootDirectory rootDirectory;

  /// Set of directories, on the store level
  late final StoreDirectory? storeDirectory;

  /// Forces statistic getters to recalculate and override any statistic caches that might exist
  ///
  /// Use sparingly, as some calculations can be expensive. Will be necessary if you alter the store manually.
  final bool forceRecalculation;

  /// Manages caching statistics and general running (synchronously or asynchronously)
  ///
  /// See [StorageCachingTileProvider] for object that manages browse caching and bulk downloading
  ///
  /// All operations have two versions (synchronous and asynchronous). The first provides decreases code complexity at the expense of worse performance; the latter is the opposite.
  ///
  /// Functions may throw errors if requirements aren't met: for example, [allStoresSizes] requires the [rootDirectory] to exist, whilst [storeSize] requires [storeDirectory] to exist.
  MapCachingManager({
    RootDirectory? rootDir,
    StoreDirectory? storeDir,
    this.forceRecalculation = false,
  }) {
    storeDirectory = storeDir;

    if (rootDir == null && storeDir != null) rootDir = storeDir.rootDirectory;

    if (rootDir == null && storeDir == null) {
      throw ArgumentError(
          'At least one of `rootDirectory` and/or `storeDirectory` must be provided as an argument');
    }
  }

  //! WATCHERS !//

  /// Watch for changes in the current cache
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// By default, [recursive] is set to `false`, meaning only top level changes (those to do with each store) will be caught. Enable recursivity to also include events from [watchStoreChanges].
  ///
  /// Only supported on some platforms. Will throw [UnsupportedError] if platform has no internal support (eg. OS X 10.6 and below). Note that recursive watching is not supported on some other platforms, but handling for this is unspecified.
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
    _rootRequired;

    if (!FileSystemEntity.isWatchSupported) {
      throw UnsupportedError(
          'Watching is not supported on the current platform');
    }

    final Stream<void> stream = rootDirectory.rootDirectory
        .watch(events: fileSystemEvents)
        .map((_) => null)
        .mergeAll(
          allStoresNames
              .map((name) =>
                  StoreDirectory(rootDirectory: rootDirectory, storeName: name))
              .map(
                (store) => MapCachingManager(storeDir: store)
                    .watchStoreChanges(enableDebounce)
                    .map((e) => null),
              ),
        );

    //final Stream<void> stream = storeDirectory!.tileStorage
    //    .watch(events: fileSystemEvents, recursive: true)
    //   .map((_) => null);

    return enableDebounce ? stream.debounce(debounceDuration) : stream;
  }

  /// Watch for changes in the current store
  ///
  /// Useful to update UI only when required, for example, in a [StreamBuilder]. Whenever this has an event, it is likely the other statistics will have changed.
  ///
  /// Only supported on some platforms. Will throw [UnsupportedError] if platform has no internal support (eg. OS X 10.6 and below).
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

    if (!FileSystemEntity.isWatchSupported) {
      throw UnsupportedError(
          'Watching is not supported on the current platform');
    }

    final Stream<void> stream = storeDirectory!.storeDirectory
        .watch(events: fileSystemEvents)
        .map((event) => null);

    return enableDebounce ? stream.debounce(debounceDuration) : stream;
  }

  //! STATISTIC GETTERS !//

  String _cachedStatisticGetter(
      String statType, dynamic Function() calculation) {
    final File f =
        storeDirectory!.purposeDirectories[PurposeDirectory.stats]! >>>
            '$statType.cache';

    if (!forceRecalculation && f.existsSync()) {
      return f.readAsStringSync();
    } else {
      final String calculated = calculation().toString();
      f.writeAsStringSync(calculated, flush: true);
      return calculated;
    }
  }

  /// Retrieve a list of all names of existing stores
  List<String> get allStoresNames {
    _rootRequired;

    List<String> returnable = [];
    for (FileSystemEntity e in rootDirectory.rootDirectory
        .listSync(followLinks: false, recursive: false)) {
      returnable.add(p.split(e.absolute.path).last);
    }

    return returnable;
  }

  /// Retrieve the size of a store in kibibytes (KiB)
  double get storeSize {
    _storeRequired;

    return double.parse(_cachedStatisticGetter(
      'size',
      () {
        int totalSize = 0;
        for (FileSystemEntity e
            in storeDirectory!.storeDirectory.listSync(recursive: true)) {
          totalSize += e is File ? e.lengthSync() : 0;
        }

        return totalSize / 1024;
      },
    ));
  }

  /// Retrieve the size of all stores in kibibytes (KiB)
  double get allStoresSizes {
    _rootRequired;

    double returnable = 0;
    for (String name in allStoresNames) {
      returnable +=
          copyWith(storeDir: storeDirectory!.copyWith(storeName: name))
              .storeSize;
    }

    return returnable;
  }

  /// Retrieve the number of stored tiles in a store
  int get storeLength {
    _storeRequired;

    return int.parse(_cachedStatisticGetter(
      'length',
      () => storeDirectory!.purposeDirectories[PurposeDirectory.tiles]!
          .listSync()
          .length,
    ));
  }

  /// Retrieve the number of stored tiles in all stores
  int get allStoresLengths {
    _rootRequired;

    int returnable = 0;
    for (String name in allStoresNames) {
      returnable +=
          copyWith(storeDir: storeDirectory!.copyWith(storeName: name))
              .storeLength;
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

    for (FileSystemEntity evt in storeDirectory!
        .purposeDirectories[PurposeDirectory.tiles]!
        .listSync()) {
      if (i >= (randInt ?? 0)) {
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

  //! DEPRECATED !//

  /// Deprecated in favour of now non-blocking normal constructor. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of now non-blocking normal constructor. Migrate your code before the next minor release.')
  static Future<MapCachingManager> async({
    RootDirectory? rootDir,
    StoreDirectory? storeDir,
  }) =>
      Future.sync(
          () => MapCachingManager(rootDir: rootDir, storeDir: storeDir));

  /// Deprecated in favour of direct construction through [RootDirectory.normalCache]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of direct construction through [CacheDirectory.normalCache]. Migrate your code before the next minor release.')
  static Future<Directory> get normalCache async =>
      (await RootDirectory.normalCache).rootDirectory;

  /// Deprecated in favour of direct construction through [RootDirectory.temporaryCache]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of direct construction through [CacheDirectory.temporaryCache]. Migrate your code before the next minor release.')
  static Future<Directory> get temporaryCache async =>
      (await RootDirectory.temporaryCache).rootDirectory;

  /// Deprecated in favour of [StoreDirectory.ready]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of [StoreDirectory.ready]. Migrate your code before the next minor release.')
  bool? exists(String storeName) {
    _storeRequired;
    return storeDirectory!.ready;
  }

  /// Deprecated in favour of [StoreDirectory.reset]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of [StoreDirectory.reset]. Migrate your code before the next minor release.')
  void emptyStore() {
    _storeRequired;

    storeDirectory!.delete();
    storeDirectory!.create();
  }

  /// Deprecated in favour of [RootDirectory.clean]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of [RootDirectory.clean]. Migrate your code before the next minor release.')
  void deleteAllStores() {
    _rootRequired;
    rootDirectory.clean();
  }

  /// Deprecated in favour of [StoreDirectory.rename]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of [StoreDirectory.rename]. Migrate your code before the next minor release.')
  MapCachingManager renameStore(String newName) {
    _storeRequired;
    return copyWith(storeDir: storeDirectory!.rename(newName));
  }

  /// Deprecated in favour of [StoreDirectory.delete]. Migrate your code before the next minor release.
  @Deprecated(
      'Deprecated in favour of [StoreDirectory.delete]. Migrate your code before the next minor release.')
  void deleteStore() {
    _storeRequired;
    storeDirectory!.delete();
  }

  //! SHARED REQUIRERS !//

  /// Functions that require [storeDirectory] should call to ensure they are usable
  ///
  /// If this doesn't throw, [rootDirectory] should also be available.
  ///
  /// Superset of [_rootRequired].
  void get _storeRequired {
    if (storeDirectory == null || !storeDirectory!.ready) {
      throw ArgumentError(
          '`storeDirectory` must be provided as an argument to use this method');
    }
  }

  /// Functions that require [rootDirectory] should call to ensure they are usable
  ///
  /// Subset of [_storeRequired].
  void get _rootRequired {
    if (!rootDirectory.ready) {
      throw ArgumentError(
          '`rootDirectory` or `storeDirectory` must be provided as an argument to use this method');
    }
  }

  //! GENERAL OBJECT STUFF !//

  MapCachingManager copyWith({
    RootDirectory? rootDir,
    StoreDirectory? storeDir,
  }) {
    return MapCachingManager(
      rootDir: rootDir ?? rootDirectory,
      storeDir: storeDir ?? storeDirectory,
    );
  }

  @override
  String toString() =>
      'MapCachingManager(rootDirectory: $rootDirectory, storeDirectory: $storeDirectory)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapCachingManager &&
        other.rootDirectory == rootDirectory &&
        other.storeDirectory == storeDirectory;
  }

  @override
  int get hashCode => rootDirectory.hashCode ^ storeDirectory.hashCode;
}
