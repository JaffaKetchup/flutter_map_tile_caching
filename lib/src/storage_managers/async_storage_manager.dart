import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart' show Image;
import 'package:path/path.dart' as p show joinAll, split;

import '../main.dart';
import '../misc/validate.dart';
import 'storage_manager.dart';

/// Manages caching statistics and general running (synchronously or asynchronously)
///
/// See [StorageCachingTileProvider] for object that manages browse caching and bulk downloading
///
/// On initialisation, automatically creates the cache & store, if applicable, if they do not exist. Store will not be created if not specified.
///
/// All operations have two versions (synchronous and asynchronous). The first provides decreases code complexity at the expense of worse performance; the latter is the opposite.
///
/// Functions may throw errors if requirements aren't met: for example, [allStoresNames] requires the [parentDirectory] to exist, whilst [storeName] requires [storeDirectory] to exist, and therefore [storeName] not to be `null`.
extension AsyncMapCachingManager on MapCachingManager {
  /// Check if the store exists
  ///
  /// Returns `true` if it does, `false` if only the [parentDirectory] exists, `null` if neither exist.
  Future<bool?> get existsAsync async {
    try {
      await _storeRequired;
    } catch (e) {
      return null;
    }

    try {
      await _cacheRequired;
    } catch (e) {
      return false;
    }

    return true;
  }

  /// Delete a store
  ///
  /// To only empty the store, see [emptyStoreAsync].
  Future<void> deleteStoreAsync() async {
    await _storeRequired;
    await storeDirectory!.delete(recursive: true);
  }

  /// Empty a store (delete all contained tiles and metadata)
  Future<void> emptyStoreAsync() async {
    await _storeRequired;

    await for (FileSystemEntity e in storeDirectory!.list(recursive: true)) {
      await e.delete();
    }
  }

  /// Delete all stores
  Future<void> deleteAllStoresAsync() async {
    await _cacheRequired;
    await parentDirectory.delete(recursive: true);
  }

  /// Rename the current store
  ///
  /// The old [MapCachingManager] will still retain it's link to the old store, so always use the new returned value instead: returns a new [MapCachingManager] after a successful renaming operation.
  ///
  /// An error will be thrown if the new store name is invalid, see [validateStoreNameString] to validate names safely beforehand.
  Future<MapCachingManager> renameStoreAsync(String newName) async {
    await _storeRequired;

    final String safeNewName =
        safeFilesystemString(inputString: newName, throwIfInvalid: true);
    await storeDirectory!
        .rename(p.joinAll([parentDirectory.absolute.path, safeNewName]));

    return await MapCachingManager.async(parentDirectory, safeNewName);
  }

  /// Retrieve a list of all names of existing stores
  Future<List<String>> get allStoresNamesAsync async {
    await _cacheRequired;

    return await parentDirectory
        .list()
        .map((e) => p.split(e.absolute.path).last)
        .toList();
  }

  /// Retrieve the size of a store in kibibytes (KiB)
  Future<double> get storeSizeAsync async {
    await _storeRequired;

    return (await storeDirectory!.list().asyncMap((e) async {
          if (e is! File) return 0;

          try {
            return await e.length();
          } catch (e) {
            return 0;
          }
        }).toList())
            .sum /
        1024;
  }

  /// Retrieve the size of all stores in kibibytes (KiB)
  Future<double> get allStoresSizesAsync async {
    await _cacheRequired;

    return (await parentDirectory
            .list()
            .asyncMap(
              (e) async =>
                  (await (e as Directory)
                          .list()
                          .asyncMap(
                              (f) async => f is File ? await f.length() : 0)
                          .toList())
                      .sum /
                  1024,
            )
            .toList())
        .sum;
  }

  /// Retrieve the number of stored tiles in a store
  Future<int> get storeLengthAsync async {
    await _storeRequired;
    return await storeDirectory!.list().length;
  }

  /// Retrieve the number of stored tiles in all stores
  Future<int> get allStoresLengthsAsync async {
    await _cacheRequired;

    return (await parentDirectory
            .list()
            .asyncMap((e) async => await (e as Directory).list().length)
            .toList())
        .sum;
  }

  /// Retrieves a (potentially random) tile from the store and uses it to create a cover [Image]
  ///
  /// [random] controls whether the chosen tile is chosen at random or whether the chosen tile is the 'first' tile in the store. Note that 'first' means alphabetically, not chronologically.
  ///
  /// Using random mode may take a while to generate if the random number is large.
  ///
  /// If using random mode, optionally set [maxRange] to an integer (1 <= [maxRange] <= [storeLength]) to only generate a random number between 0 and the specified number. Useful to reduce waiting times or enforce consistency.
  ///
  /// Returns `null` there are no cached tiles.
  Future<Image?> coverImageAsync({
    required bool random,
    int? maxRange,
    double? size,
  }) async {
    await _storeRequired;

    final int storeLen = await storeLengthAsync;
    if (storeLen == 0) return null;

    if (!random && maxRange != null) {
      throw ArgumentError(
          'If not in random mode, `maxRange` must be left as `null`');
    }
    if (maxRange != null && (maxRange < 1 || maxRange > storeLen)) {
      throw ArgumentError(
          'If specified, `maxRange` must be more than or equal to 1 and less than or equal to `storeLength`');
    }

    final int randInt =
        random ? Random().nextInt(maxRange ?? storeLen + 1) : -1;

    int i = 0;

    await for (FileSystemEntity e in storeDirectory!.list()) {
      if (!random || i == randInt) {
        return Image.file(
          File(e.absolute.path),
          width: size,
          height: size,
        );
      }
      i++;
    }
  }

  /// Functions that require [storeDirectory] or [storeName] should call to ensure they are usable
  ///
  /// Superset of [_cacheRequired].
  Future<void> get _storeRequired async {
    if (storeDirectory == null || !(await storeDirectory!.exists())) {
      throw '`storeName` is required, and `parentDirectory` must exist, to use this function';
    }
  }

  /// Functions that require [parentDirectory] should call to ensure they are usable
  ///
  /// Subset of [_storeRequired].
  Future<void> get _cacheRequired async {
    if (!(await parentDirectory.exists())) {
      throw '`parentDirectory` must exist to use this function';
    }
  }
}
