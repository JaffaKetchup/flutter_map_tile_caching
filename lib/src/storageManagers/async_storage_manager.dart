import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p show joinAll, split;

import 'storage_manager.dart';

/// Handles caching for tiles (synchronously or asynchronously)
///
/// On initialisation, automatically creates the cache store if it does not exist.
///
/// All operations have two versions (synchronous and asynchronous). The first provides decreases code complexity at the expense of worse performance; the latter is the opposite.
extension AsyncMapCachingManager on MapCachingManager {
  /// Check if the cache store exists
  ///
  /// Returns `true` if it does, `false` if only the [parentDirectory] exists, `null` if neither exist.
  Future<bool?> get existsAsync async => await Directory(storePath).exists()
      ? true
      : await Directory(parentDirectory.absolute.path).exists()
          ? false
          : null;

  /// Delete a cache store
  Future<void> deleteStoreAsync() async {
    if (await existsAsync ?? false) {
      await Directory(storePath).delete(recursive: true);
    }
  }

  /// Empty a cache store (delete all contained tiles)
  Future<void> emptyStoreAsync() async {
    if (await existsAsync ?? false) {
      await Directory(storePath).list(recursive: true).forEach((element) async {
        await element.delete();
      });
    }
  }

  /// Delete all cache stores
  Future<void> deleteAllStoresAsync() async {
    if (await existsAsync != null) {
      await Directory(parentDirectory.absolute.path).delete(recursive: true);
    }
  }

  /// Rename the current cache store to a new name
  ///
  /// The old [MapCachingManager] will still retain it's link to the old store, so always use the new returned value instead: returns a new [MapCachingManager] after a successful renaming operation or `null` if the cache does not exist.
  Future<MapCachingManager?> renameStoreAsync(String newName) async {
    if (await existsAsync == null) return null;
    await Directory(storePath)
        .rename(p.joinAll([parentDirectory.absolute.path, newName]));
    return MapCachingManager(parentDirectory, newName);
  }

  /// Retrieve a list of all names of existing cache stores
  ///
  /// Returns `null` if the cache does not exist.
  Future<List<String>?> get allStoresNamesAsync async {
    if (await existsAsync == null) return null;

    return Directory(parentDirectory.absolute.path)
        .list()
        .map((e) => p.split(e.absolute.path).last)
        .toList();
  }

  /// Retrieve the size of a cache store in kibibytes (KiB)
  ///
  /// Returns `null` if the store does not exist.
  Future<double?> get storeSizeAsync async {
    if (!(await existsAsync ?? false)) return null;

    int totalSize = 0;
    await for (FileSystemEntity e in Directory(storePath).list()) {
      totalSize += e is File ? await e.length() : 0;
    }

    return totalSize / 1024;
  }

  /// Retrieve the size of all cache stores in kibibytes (KiB)
  ///
  /// Returns `null` if the cache does not exist.
  Future<double?> get allStoresSizesAsync async {
    if (await existsAsync == null) return null;

    double returnable = 0;
    for (String storeName in (await allStoresNamesAsync)!) {
      returnable +=
          await MapCachingManager(parentDirectory, storeName).storeSizeAsync ??
              0;
    }

    return returnable;
  }

  /// Retrieve the number of stored tiles in a cache store
  ///
  /// Returns `null` if the store does not exist.
  Future<int?> get storeLengthAsync async {
    if (!(await existsAsync ?? false)) return null;
    return await Directory(storePath).list().length;
  }

  /// Retrieve the number of stored tiles in all cache stores
  ///
  /// Returns `null` if the cache does not exist.
  Future<int?> get allStoresLengthsAsync async {
    if (await existsAsync == null) return null;

    int returnable = 0;
    for (String storeName in (await allStoresNamesAsync)!) {
      returnable +=
          await Directory(p.joinAll([parentDirectory.absolute.path, storeName]))
              .list(recursive: true)
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
  Future<Image?> coverImageAsync({
    required bool random,
    int? maxRange,
    double? size,
  }) async {
    final int? storeLen = await storeLengthAsync;

    if (!(await existsAsync ?? false)) return null;
    if (storeLen == 0 || storeLen == null) return null;

    assert(
      random ? true : maxRange == null,
      'If not in random mode, `maxRange` must be left as `null`',
    );
    assert(
      (maxRange ?? 1) >= 1 && (maxRange ?? 1) <= storeLen,
      'If specified, `maxRange` must be more than or equal to 1 and less than or equal to `storeLength`',
    );

    final int randInt =
        random ? Random().nextInt(maxRange ?? (storeLen + 1)) : -1;

    int i = 0;

    await for (FileSystemEntity evt in Directory(storePath).list()) {
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
}
