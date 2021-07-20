import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p show joinAll;

import 'regions/downloadableRegion.dart';

/// Multiple behaviors dictating how caching should be carried out, if at all
enum CacheBehavior {
  /// Only get tiles from the cache
  ///
  /// No tile will be cached. If the cached tile is not available, an error will be raised.
  cacheOnly,

  /// Try to get tiles from the cache before looking online
  ///
  /// A tile may be cached. If the cached tile is not available, and the Internet/tile is unreachable, an error will be raised.
  ///
  /// This is the default behaviour.
  cacheFirst,

  /// Update cache from the Internet
  ///
  /// A tile may be cached. If the Internet is unreachable, an error will be raised.
  cacheRenew,

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
  /// Deprecated. Will be removed in the next release. Migrate to `maxStoreLength`.
  @Deprecated(
    'This variable has been deprecated, and will be removed in the next release. Migrate to `maxStoreLength`.',
  )
  static final kMaxPreloadTileAreaCount = 20000;

  /// The maximum number of tiles allowed in a cache store ('browsing', see below) before the oldest tile gets deleted.
  ///
  /// Only applies to 'browse caching', ie. downloading regions will bypass this limit. Please note that this can be computationally expensive as it potentially involves sorting through this many files to find the oldest file.
  ///
  /// Defaults to 20000, set to 0 to disable.
  final int maxStoreLength;

  /// The duration until a tile expires and needs to be fetched again when browsing.
  ///
  /// Only has an effect when the `CacheBehavior` is set to `cacheFirst`.
  ///
  /// Defaults to 31 days, set to 0 to disable.
  final Duration cachedValidDuration;

  /// The name of the cache store to use for this instance. Defaults to the default store, 'mainCache'.
  final String storeName;

  /// The directory to place cache stores into.
  ///
  /// Use `await MapStorageManager.normalDirectory` wherever possible, or `await MapStorageManager.temporaryDirectory` is required (see documentation). If creating a path manually, be sure it's the correct format, use the `path` library if needed.
  ///
  /// Required.
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
    this.maxStoreLength = 20000,
    this.cachedValidDuration = const Duration(days: 31),
    this.storeName = 'mainCache',
    this.behavior = CacheBehavior.cacheFirst,
    required this.parentDirectory,
  });

  //! GETTER FUNCTIONS !//

  Future<void> _getAndSaveTile(
    Coords<num> coord,
    TileLayerOptions options,
    http.Client client,
    Function(String, dynamic) errorHandler,
  ) async {
    final Coords<double> coordDouble =
        Coords(coord.x.toDouble(), coord.y.toDouble())..z = coord.z.toDouble();
    final String url = getTileUrl(coordDouble, options);

    try {
      Directory(p.joinAll([parentDirectory.path, storeName]))
          .createSync(recursive: true);
      File(
        p.joinAll([
          parentDirectory.path,
          storeName,
          url
              .replaceAll('https://', '')
              .replaceAll('http://', '')
              .replaceAll("/", "")
              .replaceAll(".", "")
        ]),
      ).writeAsBytesSync((await client.get(Uri.parse(url))).bodyBytes);
    } catch (e) {
      errorHandler(url, e);
    }
  }

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to cache for later
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final File fileReal = File(p.joinAll([
      parentDirectory.path,
      storeName,
      getTileUrl(coords, options)
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll("/", "")
          .replaceAll(".", "")
    ]));

    NetworkToFileImage ntfi(bool url, bool file) {
      try {
        List<FileSystemEntity>? fileList;
        if (maxStoreLength != 0 &&
            file &&
            url &&
            Directory(p.joinAll([parentDirectory.path, storeName]))
                .existsSync())
          fileList = Directory(p.joinAll([parentDirectory.path, storeName]))
              .listSync();

        if (fileList != null &&
            fileList.isNotEmpty &&
            fileList.length + 1 > maxStoreLength) {
          /*FileSystemEntity? currentOldestFile;
          DateTime currentOldestTime = DateTime(9999);
          fileList.forEach((element) {
            DateTime mod = element.statSync().modified;
            if (mod.isBefore(currentOldestTime)) {
              currentOldestFile = element;
              currentOldestTime = mod;
            }
          });
          currentOldestFile!.deleteSync();*/
          fileList.sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
          fileList[0].deleteSync();
        }
        return NetworkToFileImage(
          url: url ? getTileUrl(coords, options) : null,
          file: file ? fileReal : null,
        );
      } catch (e) {
        throw CachedNotAvailable();
      }
    }

    Directory(p.joinAll([parentDirectory.path, storeName]))
        .createSync(recursive: true);

    if (behavior == CacheBehavior.onlineOnly)
      return ntfi(true, false);
    else if (behavior == CacheBehavior.cacheOnly)
      return ntfi(false, true);
    else {
      if (behavior == CacheBehavior.cacheRenew ||
          (fileReal.existsSync() &&
              fileReal
                  .lastModifiedSync()
                  .add(cachedValidDuration)
                  .isBefore(DateTime.now())))
        File(
          p.joinAll([
            parentDirectory.path,
            storeName,
            getTileUrl(coords, options)
                .replaceAll('https://', '')
                .replaceAll('http://', '')
                .replaceAll("/", "")
                .replaceAll(".", "")
          ]),
        ).deleteSync();
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
        region.crs,
        region.tileSize,
      );
    } else if (region.type == RegionType.rectangle) {
      yield* _downloadRectangle(
        LatLngBounds.fromPoints(region.points),
        region.minZoom,
        region.maxZoom,
        region.options,
        region.errorHandler,
        region.crs,
        region.tileSize,
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
  /// Only available on Android devices, due to limitations with other operating systems. This may be slower and/or less stable than conducting the download in the foreground.
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use `checkRegion()`.
  ///
  /// You may want to call `requestIgnoreBatteryOptimizations()` before hand, depending on how/where/why this background download will be used. See documentation on that method for more information.
  ///
  /// Optionally specify `showNotification` as `false` to disable the built-in notification system.
  ///
  /// Optionally specify a `callback` that gets fired every time another tile is downloaded/failed, takes one `DownloadProgress` argument, and returns a boolean. Download can be cancelled by returning `true` from `callback` function or by fully closing the app.
  ///
  /// If the download doesn't seem to start on a testing device, try changing `useAltMethod` to `true`. This will switch to an older Android API, so should only be used if it is the most stable on a device. You may be able to programatically detect if the download hasn't started by using the callback, therefore allowing you to call this method again with `useAltMethod`, but this isn't guranteed.
  ///
  /// Returns nothing.
  void downloadRegionBackground(
    DownloadableRegion region, {
    bool showNotification = true,
    bool Function(DownloadProgress)? callback,
    bool useAltMethod = false,
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
          forceAlarmManager: useAltMethod,
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
