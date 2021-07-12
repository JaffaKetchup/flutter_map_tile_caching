import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_tile_caching/src/storageManager.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'regions/downloadableRegion.dart';

/// Multiple behaviors dictating how caching should be carried out, if at all
enum CacheBehavior {
  /// Only get tiles from the cache
  ///
  /// No tile will be cached. If the tile is not available, an error will be raised.
  cacheOnly,

  /// Try to get tiles from the cache before looking online
  ///
  /// A tile may be cached. If the cached tile is not available, and the Internet/tile is unreachable, an error will be raised.
  ///
  /// This is the default behaviour.
  cacheFirst,

  /// Only get tiles from the Internet
  ///
  /// No tile will be cached. If the Internet/tile is unreachable, an error will be raised.
  onlineOnly,
}

/// An error that:
/// 'The tile could not be found in the cache, and the Internet was either unallowed or unreachable.'
class CachedNotAvailable implements Exception {
  /// A message instead of the default message
  final String message;

  /// Creates an error that:
  /// 'The tile could not be found in the cache, and the Internet was either unallowed or unreachable.'
  @internal
  CachedNotAvailable([
    this.message =
        'The tile could not be found in the cache, and the Internet was either unallowed or unreachable.',
  ]);
}

/// A `TileProvider` to automatically cache browsed (panned over) tiles to a local caching database
///
/// Also contains methods to download regions of a map to a local caching database using an instance
///
/// Optionally pass a vaild cache duration to override the default 31 days, or pass the name of a cache store to use it instead of the default.
///
/// See online documentation for more information about the caching/downloading behaviour of this library.
class StorageCachingTileProvider extends TileProvider {
  /// The maximum number of downloadable tiles
  static final kMaxPreloadTileAreaCount = 20000;

  /// The duration until a tile expires and needs to be fetched again. Defaults to 31 days.
  final Duration cachedValidDuration;

  /// The name of the cache store to use for this instance. Defaults to the default cache, 'mainCache'.
  final String storeName;

  /// Whether to automatically load surrounding tiles to avoid the appearance of grey tiles. Defaults to `false`.
  //final bool preloadSurroundings;

  /// The directory to place cache stores into. Use `await StorageCachingTileProvider.normalDirectory` wherever possible. Required.
  final Directory parentDirectory;

  /// The behavior method to get the tile. Defaults to `cacheFirst`.
  final CacheBehavior behavior;

  /// Create a `TileProvider` to automatically cache browsed (panned over) tiles to a local caching database
  ///
  /// Also contains methods to download regions of a map to a local caching database using an instance
  ///
  /// Optionally pass a vaild cache duration to override the default 31 days, or pass the name of a cache store to use it instead of the default.
  ///
  /// See online documentation for more information about the caching/downloading behaviour of this library.
  StorageCachingTileProvider({
    this.cachedValidDuration = const Duration(days: 31),
    this.storeName = 'mainCache',
    //this.preloadSurroundings = false,
    this.behavior = CacheBehavior.cacheFirst,
    required this.parentDirectory,
  });

  //! GETTER FUNCTIONS !//

  /// Get the application's documents directory
  ///
  /// Caching in here will show caches under the App Storage - instead of under App Cache - in Settings, and therefore the OS or other apps cannot clear the cache without telling the user.
  static Future<Directory> get normalDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get the temporary storage directory
  ///
  /// Caching in here will show caches under the App Cache - instead of App Storage - in Settings. Therefore the OS can clear cached tiles at any time without telling the user.
  ///
  /// For this reason, it is not recommended to use this store. Use `normalDirectory` by default instead.
  static Future<Directory> get unstableDirectory async {
    return await getTemporaryDirectory();
  }

  Future<void> _getAndSaveTile(
    Coords<num> coord,
    TileLayerOptions options,
    http.Client client,
    Function(String, dynamic) errorHandler,
  ) async {
    final Coords<double> coordDouble =
        Coords(coord.x.toDouble(), coord.y.toDouble())..z = coord.z.toDouble();
    final String url = getTileUrl(coordDouble, options);

    await TileStorageManager(parentDirectory, storeName).newTile(
      url: url,
      client: client,
      errorHandler: (e) => errorHandler(url, e),
    );
  }

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to cache for later
  @override
  /*ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    if (preloadSurroundings) {
      for (double x = coords.x - 6; x < coords.x + 6; x++) {
        for (double y = coords.y - 6; y < coords.y + 6; y++) {
          //? Paint tiles here //
          throw UnimplementedError();
        }
      }
    }
    return _CachedTileImageProvider(
      getTileUrl(coords, options),
      Coords<num>(coords.x, coords.y)..z = coords.z,
      cacheName: cacheName,
    );
  }*/
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final File fileReal = File(
      parentDirectory.path +
          '/$storeName/tiles/' +
          getTileUrl(coords, options)
              .replaceAll('https://', '')
              .replaceAll('http://', '')
              .replaceAll("/", ""),
    );

    NetworkToFileImage ntfi(bool url, bool file) {
      try {
        return NetworkToFileImage(
          url: url ? getTileUrl(coords, options) : null,
          file: file ? fileReal : null,
        );
      } catch (e) {
        throw CachedNotAvailable();
      }
    }

    if (behavior == CacheBehavior.onlineOnly) {
      return ntfi(true, false);
    } else if (behavior == CacheBehavior.cacheOnly) {
      if (!Directory(parentDirectory.path + '/$storeName/tiles/').existsSync())
        throw CachedNotAvailable();
      return ntfi(false, true);
    } else {
      Directory(parentDirectory.path + '/$storeName/tiles/')
          .createSync(recursive: true);

      if (fileReal.existsSync() &&
          fileReal
              .lastModifiedSync()
              .add(cachedValidDuration)
              .isBefore(DateTime.now()))
        TileStorageManager(parentDirectory, storeName).deleteTile(
          fileName: getTileUrl(coords, options)
              .replaceAll('https://', '')
              .replaceAll('http://', '')
              .replaceAll("/", ""),
        );
      return ntfi(true, true);
    }
  }

  //! DOWNLOAD (FOREGROUND) FUNCTIONS !//

  /// Download a specified `DownloadableRegion` in the foreground
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use `checkRegion()`.
  ///
  /// Streams a `DownloadProgress` object containing the number of completed tiles, total number of tiles to download, a list of errored URLs and the percentage completion.
  Stream<DownloadProgress> downloadRegion(DownloadableRegion region) async* {
    if (region.type == RegionType.circle) {
      yield* _downloadCircle(
        region.points,
        region.minZoom,
        region.maxZoom,
        region.options,
        region.errorHandler,
      );
    } else if (region.type == RegionType.rectangle) {
      yield* _downloadRectangle(
        LatLngBounds.fromPoints(region.points),
        region.minZoom,
        region.maxZoom,
        region.options,
        region.errorHandler,
      );
    } else if (region.type == RegionType.line) {
      throw UnimplementedError();
    } else if (region.type == RegionType.customPolygon) {
      throw UnimplementedError();
    }
  }

  /// Check how many downloadable tiles are within a specified `DownloadableRegion`
  ///
  /// Returns an `int` which is the number of tiles.
  static int checkRegion(DownloadableRegion region) {
    if (region.type == RegionType.circle) {
      return _circleTiles(
        region.points,
        region.minZoom,
        region.maxZoom,
      ).length;
    } else if (region.type == RegionType.rectangle) {
      return _rectangleTiles(
        LatLngBounds.fromPoints(region.points),
        region.minZoom,
        region.maxZoom,
      ).length;
    } else if (region.type == RegionType.line) {
      throw UnimplementedError();
    } else if (region.type == RegionType.customPolygon) {
      throw UnimplementedError();
    }
    throw UnimplementedError();
  }

  //! DOWNLOAD (BACKGROUND) FUNCTIONS !//

  /// Request to be excluded from battery optimizations (allows background task to run when app minimized)
  ///
  /// Only available on Android devices, due to limitations with other operating systems.
  ///
  /// Pops up an intrusive system dialog asking to be given the permission. There is no explanation for the user, except that the app will be allowed to run in the background all the time, so less technical users may be put off. It is up to you to decide (and program accordingly) if you want to show a reason first, then request the permission.
  ///
  /// Not needed if background download is only intented to be used whilst still within the app. If this is not granted, minimizing the app will usually pause the task. Closing the app fully will always cancel the task, no matter what this permission is.
  ///
  /// Will return (`Future`) `true` if permission was granted, `false` if the permission was denied.
  static Future<bool> requestIgnoreBatteryOptimizations(
      BuildContext context) async {
    if (io.Platform.isAndroid) {
      final PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied || status.isLimited) {
        final PermissionStatus statusAfter =
            await Permission.ignoreBatteryOptimizations.request();
        if (statusAfter.isGranted) return true;
        return false;
      } else if (status.isGranted) {
        return true;
      } else {
        return false;
      }
    } else
      throw UnsupportedError(
          'The background download feature is only available on Android due to limitations with other operating systems.');
  }

  /// Download a specified `DownloadableRegion` in the background, and show a notification progress bar (by default)
  ///
  /// Only available on Android devices, due to limitations with other operating systems.
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use `checkRegion()`.
  ///
  /// You may want to call `requestIgnoreBatteryOptimizations()` before hand, depending on how/where/why this background download will be used. See documentation on that function for more information.
  ///
  /// Optionally specify a `callback` that gets fired every time another tile is downloaded/failed, takes one `DownloadProgress` argument, and returns a boolean.
  ///
  /// Download can be cancelled by returning `true` from `callback` function or by fully closing the app.
  ///
  /// Returns nothing.
  void downloadRegionBackground(
    DownloadableRegion region, {
    bool showNotification = true,
    bool Function(DownloadProgress)? callback,
  }) async {
    if (io.Platform.isAndroid) {
      FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
        ),
        (String taskId) async {
          if (taskId == 'backgroundTileDownload') {
            // ignore: cancel_subscriptions
            StreamSubscription<DownloadProgress>? sub;
            sub = downloadRegion(region).listen((event) async {
              AndroidNotificationDetails androidPlatformChannelSpecifics =
                  AndroidNotificationDetails(
                'MapDownloading',
                'Map Background Downloader',
                'Displays progress notifications to inform the user about the progress of their map download.',
                importance: Importance.defaultImportance,
                priority: Priority.low,
                showWhen: false,
                showProgress: true,
                maxProgress: event.totalTiles,
                progress: event.completedTiles,
                visibility: NotificationVisibility.public,
                playSound: false,
                onlyAlertOnce: true,
                subText: 'Map Downloader',
              );
              NotificationDetails platformChannelSpecifics =
                  NotificationDetails(android: androidPlatformChannelSpecifics);
              if (showNotification) {
                await flutterLocalNotificationsPlugin!.show(
                  0,
                  'Map Downloading...',
                  '${event.completedTiles}/${event.totalTiles} (${event.percentageProgress.toStringAsFixed(1)}%)',
                  platformChannelSpecifics,
                );
              }

              if (callback != null) {
                if (callback(event)) {
                  sub!.cancel();
                  if (showNotification) {
                    flutterLocalNotificationsPlugin!.cancel(0);
                    await flutterLocalNotificationsPlugin.show(
                      0,
                      'Map Download Cancelled',
                      '${event.totalTiles - event.completedTiles} tiles remained',
                      platformChannelSpecifics,
                    );
                  }
                  BackgroundFetch.finish(taskId);
                }
              }

              if (event.percentageProgress == 100) {
                sub!.cancel();
                if (showNotification) {
                  flutterLocalNotificationsPlugin!.cancel(0);
                  await flutterLocalNotificationsPlugin.show(
                    0,
                    'Map Downloaded',
                    '${event.erroredTiles.length} failed tiles',
                    platformChannelSpecifics,
                  );
                }
                BackgroundFetch.finish(taskId);
              }
            });
          } else
            BackgroundFetch.finish(taskId);
        },
        (String taskId) async {
          BackgroundFetch.finish(taskId);
        },
      );
      await BackgroundFetch.scheduleTask(
        TaskConfig(
          taskId: 'backgroundTileDownload',
          delay: 1,
          forceAlarmManager: true,
        ),
      );
    } else
      throw UnsupportedError(
          'The background download feature is only available on Android due to limitations with other operating systems.');
  }

  //! CIRCLE FUNCTIONS !//

  static List<Coords<num>> _circleTiles(
    List<LatLng> circleOutline,
    int minZoom,
    int maxZoom, {
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  }) {
    final Map<int, Map<int, List<int>>> outlineTileNums = {};

    final List<Coords<num>> coords = [];

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};

      for (LatLng node in circleOutline) {
        /*
        The below code has been retained on purpose.
        DO NOT remove it.
        
        final double n = math.pow(2, zoomLvl).toDouble();
        final int x = ((node.longitude + 180.0) / 360.0 * n).toInt();
        final int y =
            ((1.0 - _asinh(math.tan(node.latitudeInRad)) / math.pi) / 2.0 * n)
                .toInt();
        */

        final CustomPoint<num> tile = crs
            .latLngToPoint(node, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .floor();

        if (outlineTileNums[zoomLvl]![tile.x.toInt()] == null) {
          outlineTileNums[zoomLvl]![tile.x.toInt()] = [
            999999999999999999,
            -999999999999999999
          ];
        }

        outlineTileNums[zoomLvl]![tile.x.toInt()] = [
          tile.y.toInt() < (outlineTileNums[zoomLvl]![tile.x.toInt()]![0])
              ? tile.y.toInt()
              : (outlineTileNums[zoomLvl]![tile.x.toInt()]![0]),
          tile.y.toInt() > (outlineTileNums[zoomLvl]![tile.x.toInt()]![1])
              ? tile.y.toInt()
              : (outlineTileNums[zoomLvl]![tile.x.toInt()]![1]),
        ];
      }

      for (int x in outlineTileNums[zoomLvl]!.keys) {
        for (int y = outlineTileNums[zoomLvl]![x]![0];
            y <= outlineTileNums[zoomLvl]![x]![1];
            y++) {
          coords.add(
            Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble(),
          );
        }
      }
    }

    return coords;
  }

  Stream<DownloadProgress> _downloadCircle(
    List<LatLng> circleOutline,
    int minZoom,
    int maxZoom,
    TileLayerOptions options, [
    Function(dynamic)? errorHandler,
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  ]) async* {
    final List<Coords<num>> tiles = _circleTiles(
      circleOutline,
      minZoom,
      maxZoom,
      crs: crs,
      tileSize: tileSize,
    );
    assert(tiles.length <= kMaxPreloadTileAreaCount,
        '${tiles.length} exceeds maximum number of pre-cacheable tiles');

    final List<String> erroredUrls = [];
    final http.Client client = http.Client();

    for (var i = 0; i < tiles.length; i++) {
      await _getAndSaveTile(tiles[i], options, client, (url, e) {
        erroredUrls.add(url);
        if (errorHandler != null) errorHandler(e);
      });
      yield DownloadProgress(
        i + 1,
        tiles.length,
        erroredUrls,
        ((i + 1) / tiles.length) * 100,
      );
    }

    client.close();
  }

  //! RECTANGLE FUNCTIONS !//

  static List<Coords> _rectangleTiles(
    LatLngBounds bounds,
    int minZoom,
    int maxZoom, {
    Crs crs = const Epsg3857(),
    tileSize = const CustomPoint(256, 256),
  }) {
    final coords = <Coords>[];
    for (var zoomLevel in List<int>.generate(
        maxZoom - minZoom + 1, (index) => index + minZoom)) {
      final nwPoint = crs
          .latLngToPoint(bounds.northWest, zoomLevel.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final sePoint = crs
              .latLngToPoint(bounds.southEast, zoomLevel.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      for (var x = nwPoint.x; x <= sePoint.x; x++) {
        for (var y = nwPoint.y; y <= sePoint.y; y++) {
          coords.add(Coords(x, y)..z = zoomLevel);
        }
      }
    }
    return coords;
  }

  Stream<DownloadProgress> _downloadRectangle(
    LatLngBounds bounds,
    int minZoom,
    int maxZoom,
    TileLayerOptions options, [
    Function(dynamic)? errorHandler,
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  ]) async* {
    final List<Coords<num>> tiles = _rectangleTiles(
      bounds,
      minZoom,
      maxZoom,
      crs: crs,
      tileSize: tileSize,
    );
    assert(tiles.length <= kMaxPreloadTileAreaCount,
        '${tiles.length} exceeds maximum number of pre-cacheable tiles');

    final List<String> erroredUrls = [];
    final http.Client client = http.Client();

    for (var i = 0; i < tiles.length; i++) {
      await _getAndSaveTile(tiles[i], options, client, (url, e) {
        erroredUrls.add(url);
        if (errorHandler != null) errorHandler(e);
      });
      yield DownloadProgress(
        i + 1,
        tiles.length,
        erroredUrls,
        ((i + 1) / tiles.length) * 100,
      );
    }

    client.close();
  }
}
