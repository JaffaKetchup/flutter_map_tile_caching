import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p show joinAll, split;

import 'misc.dart';
import 'regions/recoveredRegion.dart';

/// Handles caching for tiles
///
/// Used internally for downloading regions, another library is depended on for 'browse caching'.
class MapCachingManager {
  /// The directory to place cache stores into
  ///
  /// Use [normalCache] wherever possible, or [temporaryCache] alternatively (see documentation). To use those `Future` values, you may need to use the `async` `await` pattern. If creating a path manually, be sure it's the correct format, use the `path` library if needed.
  ///
  /// Required.
  final CacheDirectory parentDirectory;

  /// The name of a cache store. Defaults to 'mainStore'.
  final String storeName;

  /// The joined `parentDirectory` and `storeName`
  final String _joinedBasePath;

  /// Create an instance to handle caching for tiles
  ///
  /// Used internally for downloading regions, another library is depended on for 'browse caching'.
  MapCachingManager(this.parentDirectory, [this.storeName = 'mainStore'])
      : _joinedBasePath = p.joinAll([parentDirectory.absolute.path, storeName]);

  /// Check if the cache store exists
  ///
  /// Returns `true` if it does, `false` if only the [parentDirectory] exists, `null` if neither exist.
  bool? get exists => Directory(_joinedBasePath).existsSync()
      ? true
      : Directory(parentDirectory.absolute.path).existsSync()
          ? false
          : null;

  /// Explicitly create the store
  void createStore() => Directory(_joinedBasePath).createSync(recursive: true);

  /// Delete a cache store
  void deleteStore() {
    if (exists ?? false) Directory(_joinedBasePath).deleteSync(recursive: true);
  }

  /// Delete all cache stores
  void deleteAllStores() {
    if (exists != null)
      Directory(parentDirectory.absolute.path).deleteSync(recursive: true);
  }

  /// Rename the current cache store to a new name
  ///
  /// The old [MapCachingManager] will still retain it's link to the old store, so always use the new returned value instead: returns a new [MapCachingManager] after a successful renaming operation or `null` if the cache does not exist.
  MapCachingManager? renameStore(String newName) {
    if (exists == null) return null;
    Directory(_joinedBasePath)
        .renameSync(p.joinAll([parentDirectory.absolute.path, newName]));
    return MapCachingManager(parentDirectory, newName);
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

  /// Retrieve the size (in bytes) of a cache store
  ///
  /// Use `.bytesToMegabytes` on the output to get the real number of megabytes
  ///
  /// Returns `null` if the store does not exist.
  int? get storeSize {
    if (!(exists ?? false)) return null;
    return Directory(_joinedBasePath).statSync().size;
  }

  /// Retrieve the size (in bytes) of all cache stores
  ///
  /// Use `.bytesToMegabytes` on the output to get the real number of megabytes.
  ///
  /// Returns `null` if the cache does not exist.
  int? get allStoresSizes {
    if (exists == null) return null;
    int returnable = 0;
    allStoresNames!.forEach((storeName) => returnable +=
        MapCachingManager(parentDirectory, storeName).storeSize ?? 0);
    return returnable;
  }

  /// Retrieve the number of stored tiles in a cache store
  ///
  /// Returns `null` if the store does not exist.
  int? get storeLength {
    if (!(exists ?? false)) return null;
    return Directory(_joinedBasePath).listSync().length;
  }

  /// Retrieve the number of stored tiles in all cache stores
  ///
  /// Returns `null` if the cache does not exist.
  int? get allStoresLengths {
    if (exists == null) return null;
    int totalLength = 0;
    allStoresNames!.forEach((name) {
      totalLength += Directory(p.joinAll([parentDirectory.absolute.path, name]))
          .listSync(recursive: true)
          .length;
    });
    return totalLength;
  }

  @internal
  bool startRecovery(
    RegionType type,
    BaseRegion inputRegion,
    int minZoom,
    int maxZoom,
    bool preventRedownload,
    bool seaTileRemoval,
  ) {
    final File file = File(p.joinAll([_joinedBasePath, 'downloadOngoing.txt']));
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

  @internal
  void endRecovery() {
    if (!Directory(_joinedBasePath).existsSync()) return;

    File(p.joinAll([_joinedBasePath, 'downloadOngoing.txt'])).createSync();
    File(p.joinAll([_joinedBasePath, 'downloadOngoing.txt'])).deleteSync();
  }

  @internal
  RecoveredRegion? recoverDownload() {
    final File file = File(p.joinAll([_joinedBasePath, 'downloadOngoing.txt']));
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
            print(recovery[0]);
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
