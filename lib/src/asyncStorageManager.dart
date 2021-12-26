import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p show joinAll, split;
import 'package:path_provider/path_provider.dart';

import 'main.dart';
import 'misc.dart';
import 'regions/circle.dart';
import 'regions/downloadableRegion.dart';
import 'regions/line.dart';
import 'regions/recoveredRegion.dart';
import 'regions/rectangle.dart';
import 'storageManager.dart';

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
    if (await existsAsync ?? false)
      await Directory(storePath).delete(recursive: true);
  }

  /// Empty a cache store (delete all contained tiles)
  Future<void> emptyStoreAsync() async {
    if (await existsAsync ?? false)
      await Directory(storePath).list(recursive: true).forEach((element) async {
        await element.delete();
      });
  }

  /// Delete all cache stores
  Future<void> deleteAllStoresAsync() async {
    if (await existsAsync != null)
      await Directory(parentDirectory.absolute.path).delete(recursive: true);
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
    List<String> returnable = [];
    await Directory(parentDirectory.absolute.path)
        .list(followLinks: false, recursive: false)
        .forEach((dir) => returnable.add(p.split(dir.absolute.path).last));
    return returnable;
  }

  /// Retrieve the size of a cache store in kibibytes (KiB)
  ///
  /// Returns `null` if the store does not exist.
  Future<double?> get storeSizeAsync async {
    if (!(await existsAsync ?? false)) return null;

    int totalSize = 0;
    await Directory(storePath).list(recursive: true).forEach(
          (FileSystemEntity e) async =>
              totalSize += e is File ? await e.length() : 0,
        );

    return totalSize / 1024;
  }

  /// Retrieve the size of all cache stores in kibibytes (KiB)
  ///
  /// Returns `null` if the cache does not exist.
  Future<double?> get allStoresSizesAsync async {
    if (await existsAsync == null) return null;

    double returnable = 0;
    for (String storeName in (await allStoresNamesAsync)!)
      returnable +=
          await MapCachingManager(parentDirectory, storeName).storeSizeAsync ??
              0;

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
    for (String storeName in (await allStoresNamesAsync)!)
      returnable +=
          await Directory(p.joinAll([parentDirectory.absolute.path, storeName]))
              .list(recursive: true)
              .length;

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

  /// For internal use only. Recovery is managed automatically for you.
  @internal
  bool startInternalRecovery(
    RegionType type,
    BaseRegion inputRegion,
    int minZoom,
    int maxZoom,
    bool preventRedownload,
    bool seaTileRemoval,
  ) {
    final File file = File(p.joinAll([storePath, 'downloadOngoing.txt']));
    file.createSync(recursive: true);

    if (type == RegionType.rectangle) {
      final RectangleRegion region = inputRegion as RectangleRegion;
      file.writeAsStringSync(
        region.bounds.northWest.latitude.toString() +
            ',' +
            region.bounds.northWest.longitude.toString() +
            '\n' +
            region.bounds.southEast.latitude.toString() +
            ',' +
            region.bounds.southEast.longitude.toString() +
            '\n${minZoom.toString()}\n${maxZoom.toString()}\n$preventRedownload\n$seaTileRemoval\nrectangle',
        flush: true,
      );
    } else if (type == RegionType.circle) {
      final CircleRegion region = inputRegion as CircleRegion;
      file.writeAsStringSync(
        region.center.latitude.toString() +
            ',' +
            region.center.longitude.toString() +
            '\n' +
            region.radius.toString() +
            '\n${minZoom.toString()}\n${maxZoom.toString()}\n$preventRedownload\n$seaTileRemoval\ncircle',
        flush: true,
      );
    } else if (type == RegionType.line) {
      final LineRegion region = inputRegion as LineRegion;
      file.writeAsStringSync(
        region.line
                .map((pos) =>
                    pos.latitude.toString() + ',' + pos.longitude.toString())
                .join('*') +
            '\n' +
            region.radius.toString() +
            '\n${minZoom.toString()}\n${maxZoom.toString()}\n$preventRedownload\n$seaTileRemoval\nline',
        flush: true,
      );
    }

    return file.existsSync();
  }

  /// For internal use only. Recovery is managed automatically for you.
  @internal
  void endInternalRecovery() {
    if (!Directory(storePath).existsSync()) return;

    File(p.joinAll([storePath, 'downloadOngoing.txt'])).createSync();
    File(p.joinAll([storePath, 'downloadOngoing.txt'])).deleteSync();
  }

  /// For internal use only. Use [StorageCachingTileProvider.recoverDownload] instead.
  @internal
  RecoveredRegion? recoverDownloadInternally() {
    final File file = File(p.joinAll([storePath, 'downloadOngoing.txt']));
    if (!file.existsSync()) return null;

    final List<String> recovery = file.readAsLinesSync();

    final double Function(String, [double Function(String)?]) dp = double.parse;
    final int Function(String, {int Function(String)? onError, int? radix}) ip =
        int.parse;

    if (recovery[6] == 'rectangle')
      return RecoveredRegion.internal(
        type: RegionType.rectangle,
        bounds: LatLngBounds(
          LatLng(dp(recovery[0].split(',')[0]), dp(recovery[0].split(',')[1])),
          LatLng(dp(recovery[1].split(',')[0]), dp(recovery[1].split(',')[1])),
        ),
        center: null,
        line: null,
        radius: null,
        minZoom: ip(recovery[2]),
        maxZoom: ip(recovery[3]),
        preventRedownload: recovery[4] == 'true',
        seaTileRemoval: recovery[5] == 'true',
      );
    else if (recovery[6] == 'circle')
      return RecoveredRegion.internal(
        type: RegionType.circle,
        bounds: null,
        center: LatLng(
            dp(recovery[0].split(',')[0]), dp(recovery[0].split(',')[1])),
        line: null,
        radius: dp(recovery[1]),
        minZoom: ip(recovery[2]),
        maxZoom: ip(recovery[3]),
        preventRedownload: recovery[4] == 'true',
        seaTileRemoval: recovery[5] == 'true',
      );
    else
      return RecoveredRegion.internal(
        type: RegionType.line,
        bounds: null,
        center: null,
        line: recovery[0].split('*').map(
          (zip) {
            return LatLng(
              double.parse(zip.split(',')[0]),
              double.parse(zip.split(',')[1]),
            );
          },
        ).toList(),
        radius: dp(recovery[1]),
        minZoom: ip(recovery[2]),
        maxZoom: ip(recovery[3]),
        preventRedownload: recovery[4] == 'true',
        seaTileRemoval: recovery[5] == 'true',
      );
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
