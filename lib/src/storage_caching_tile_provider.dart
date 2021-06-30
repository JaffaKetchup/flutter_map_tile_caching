import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io' as io;

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tuple/tuple.dart';

import 'regions/downloadableRegion.dart';
import 'tile_storage_caching_manager.dart';

/// `TileProvider` to cache/download raster tiles inside a local caching database for `cachedValidDuration`, which default to 31 days.
///
/// See online documentation for more information about the caching/downloading behaviour of this library.
class StorageCachingTileProvider extends TileProvider {
  static final kMaxPreloadTileAreaCount = 20000;
  final Duration cachedValidDuration;
  final String cacheName;

  /// `TileProvider` to cache/download raster tiles inside a local caching database for `cachedValidDuration`, which default to 31 days.
  ///
  /// Optionally create multiple caches by choosing a unique name for each cache.
  ///
  /// See online documentation for more information about the caching/downloading behaviour of this library.
  StorageCachingTileProvider({
    this.cachedValidDuration = const Duration(days: 31),
    this.cacheName = 'mainCache',
  });

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final tileUrl = getTileUrl(coords, options);
    return CachedTileImageProvider(
      tileUrl,
      Coords<num>(coords.x, coords.y)..z = coords.z,
      cacheName: cacheName,
    );
  }

  //! DOWNLOAD FUNCTIONS !//

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

  Future<void> _getAndSaveTile(
    Coords<num> coord,
    TileLayerOptions options,
    http.Client client,
    Function(String, dynamic) errorHandler,
  ) async {
    String url = "";
    try {
      final coordDouble = Coords(coord.x.toDouble(), coord.y.toDouble())
        ..z = coord.z.toDouble();
      url = getTileUrl(coordDouble, options);
      final bytes = (await client.get(Uri.parse(url))).bodyBytes;
      await TileStorageCachingManager.saveTile(bytes, coord);
    } catch (e) {
      errorHandler(url, e);
    }
  }

  //! BACKGROUND FUNCTIONS !//

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
      BackgroundFetch.scheduleTask(
        TaskConfig(
          taskId: 'backgroundTileDownload',
          delay: 0,
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

  //! DEPRECATED FUNCTIONS !//

  /// Caching tile area by provided [bounds], zoom edges and [options].
  /// The maximum number of tiles to load is [kMaxPreloadTileAreaCount].
  /// To check tiles number before calling this method, use
  /// [approximateTileAmount].
  /// Return [Tuple3] with number of downloaded tiles as [Tuple3.item1],
  /// number of errored tiles as [Tuple3.item2], and number of total tiles that need to be downloaded as [Tuple3.item3]
  ///
  /// Deprecated. Migrate to [downloadRegion()]
  @Deprecated(
      'This function will be removed in the next release. Migrate to the Regions API as soon as possible (see docs).')
  Stream<Tuple3<int, int, int>> loadTiles(
      LatLngBounds bounds, int minZoom, int maxZoom, TileLayerOptions options,
      {Function(dynamic)? errorHandler}) async* {
    final tilesRange = approximateTileRange(
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileSize: CustomPoint(options.tileSize, options.tileSize));
    assert(tilesRange.length <= kMaxPreloadTileAreaCount,
        '${tilesRange.length} exceeds maximum number of pre-cacheable tiles');
    var errorsCount = 0;
    for (var i = 0; i < tilesRange.length; i++) {
      try {
        final cord = tilesRange[i];
        final cordDouble = Coords(cord.x.toDouble(), cord.y.toDouble());
        cordDouble.z = cord.z.toDouble();
        final url = getTileUrl(cordDouble, options);
        final bytes = (await http.get(Uri.parse(url))).bodyBytes;
        await TileStorageCachingManager.saveTile(bytes, cord);
      } catch (e) {
        errorsCount++;
        if (errorHandler != null) errorHandler(e);
      }
      yield Tuple3(i + 1, errorsCount, tilesRange.length);
    }
  }

  /// Get approximate tile amount from bounds and zoom edges
  ///
  /// Deprecated. Migrate to [checkRegion()]
  @Deprecated(
      'This function will be removed in the next release. Migrate to the Regions API as soon as possible (see docs).')
  static int approximateTileAmount({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    Crs crs = const Epsg3857(),
    tileSize = const CustomPoint(256, 256),
  }) {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    var amount = 0;
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
      final a = sePoint.x - nwPoint.x + 1;
      final b = sePoint.y - nwPoint.y + 1;
      amount += a * b as int;
    }
    return amount;
  }

  /// Get tileRange from bounds and zoom edges.
  ///
  /// Deprecated.
  @Deprecated(
      'This function will be removed in the next release, and merged to another function. Migrate to the Regions API as soon as possible (see docs).')
  static List<Coords> approximateTileRange(
      {required LatLngBounds bounds,
      required int minZoom,
      required int maxZoom,
      Crs crs = const Epsg3857(),
      tileSize = const CustomPoint(256, 256)}) {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    final cords = <Coords>[];
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
          cords.add(Coords(x, y)..z = zoomLevel);
        }
      }
    }
    return cords;
  }
}

class CachedTileImageProvider extends ImageProvider<Coords<num>> {
  final Function(dynamic)? networkErrorHandler;
  final String url;
  final Coords<num> coords;
  final Duration cacheValidDuration;
  final String cacheName;

  CachedTileImageProvider(
    this.url,
    this.coords, {
    this.cacheValidDuration = const Duration(days: 1),
    this.networkErrorHandler,
    this.cacheName = 'mainCache',
  });

  @override
  ImageStreamCompleter load(Coords<num> key, decode) =>
      MultiFrameImageStreamCompleter(
          codec: _loadAsync(cacheName: cacheName),
          scale: 1,
          informationCollector: () sync* {
            yield DiagnosticsProperty<ImageProvider>('Image provider', this);
            yield DiagnosticsProperty<Coords>('Image key', key);
          });

  @override
  Future<Coords<num>> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(coords);

  Future<Codec> _loadAsync({String cacheName = 'mainCache'}) async {
    final localBytes = await TileStorageCachingManager.getTile(
      coords,
      cacheName: cacheName,
    );
    var bytes = localBytes?.item1;
    if ((DateTime.now().millisecondsSinceEpoch -
            (localBytes?.item2.millisecondsSinceEpoch ?? 0)) >
        cacheValidDuration.inMilliseconds) {
      try {
        bytes = (await http.get(Uri.parse(url))).bodyBytes;
        await TileStorageCachingManager.saveTile(
          bytes,
          coords,
          cacheName: cacheName,
        );
      } catch (e) {
        if (networkErrorHandler != null) networkErrorHandler!(e);
      }
    }
    if (bytes == null) {
      return Future<Codec>.error('Failed to load tile for coords: $coords');
    }
    return await PaintingBinding.instance!.instantiateImageCodec(bytes);
  }
}
