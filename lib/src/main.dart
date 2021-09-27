import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:background_fetch/background_fetch.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path/path.dart' as p show joinAll;
import 'package:permission_handler/permission_handler.dart';
import 'package:queue/queue.dart';

import 'misc.dart';
import 'regions/downloadableRegion.dart';
import 'regions/recoveredRegion.dart';
import 'storageManager.dart';

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

/// A `TileProvider` to automatically cache browsed (panned over) tiles to a local caching database. Also contains methods to download regions of a map to a local caching database using an instance.
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

  /// The maximum number of tiles allowed in a cache store ('browsing', see below) before the oldest tile gets deleted
  ///
  /// Only applies to 'browse caching', ie. downloading regions will bypass this limit. Please note that this can be computationally expensive as it potentially involves sorting through this many files to find the oldest file.
  ///
  /// Also see `strictMaxLengthEnforcement`.
  ///
  /// Defaults to 20000, set to 0 to disable.
  final int maxStoreLength;

  static var maxParallel = 20;

  /// Whether to better enforce the `maxStoreLength`
  ///
  /// If multiple tile requests are made in quick succession, such as if the user moves the map quickly, the `maxStoreLength` may be broken. The limit acts as a almost like a 'suggestion', where tiles shouldn't be stored over, but may still be. Usually, an map restart (destroying and rebuilding) will help the number of tiles to go back down, but not always, and not always enough.
  ///
  /// Therefore, enabling this policy will create a loop every time a tile request is made to keep deleting the oldest tiles until the number of them is below the max. Unfortunately, this is not 100% accurate either, but it helps keep the tiles down. If the user faces performance issues, turn this off.
  ///
  /// Defaults to `true`.
  final bool betterMaxLengthEnforcement;

  /// The duration until a tile expires and needs to be fetched again when browsing
  ///
  /// Only has an effect when the `CacheBehavior` is set to `cacheFirst`.
  ///
  /// Defaults to 31 days, set to a negative duration to disable.
  final Duration cachedValidDuration;

  /// The name of the cache store to use for this instance
  ///
  /// Defaults to the default store, 'mainStore'.
  final String storeName;

  /// The directory to place cache stores into
  ///
  /// Use `await MapStorageManager.normalDirectory` wherever possible, or `await MapStorageManager.temporaryDirectory` is required (see documentation). If creating a path manually, be sure it's the correct format, use the `path` library if needed.
  ///
  /// Required.
  final CacheDirectory parentDirectory;

  /// The behavior method to get the tile
  ///
  /// Defaults to `cacheFirst`.
  final CacheBehavior behavior;

  late Isolate _isolate;
  late ReceivePort _receivePort;
  bool _downloadOngoing = false;

  /// Create a `TileProvider` to automatically cache browsed (panned over) tiles to a local caching database. Also contains methods to download regions of a map to a local caching database using an instance.
  ///
  /// Optionally pass a vaild cache duration to override the default 31 days, or pass the name of a cache store to use it instead of the default.
  ///
  /// See online documentation for more information about the caching/downloading behaviour of this library.
  StorageCachingTileProvider({
    this.maxStoreLength = 20000,
    this.betterMaxLengthEnforcement = true,
    this.cachedValidDuration = const Duration(days: 31),
    this.storeName = 'mainStore',
    this.behavior = CacheBehavior.cacheFirst,
    required this.parentDirectory,
  });

  //! TILE PROVIDER !//

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to cache for later
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final File fileReal = File(p.joinAll([
      parentDirectory.absolute.path,
      storeName,
      getTileUrl(coords, options)
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll("/", ""),
      //.replaceAll(".", "")
    ]));

    NetworkToFileImage ntfi(bool url, bool file) {
      final Directory storeDir =
          Directory(p.joinAll([parentDirectory.absolute.path, storeName]));

      bool sortAndDeleteLast() {
        final List<FileSystemEntity> fileList = storeDir.listSync();

        if (fileList.length + 1 > maxStoreLength) {
          fileList.sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
          fileList.last.deleteSync();
        }

        return fileList.length - 2 > maxStoreLength;
      }

      if (maxStoreLength != 0 && file && url && storeDir.existsSync()) {
        if (betterMaxLengthEnforcement) {
          bool reloop = true;
          while (reloop) {
            reloop = sortAndDeleteLast();
          }
        } else
          sortAndDeleteLast();
      }

      try {
        return NetworkToFileImage(
          url: url ? getTileUrl(coords, options) : null,
          file: file ? fileReal : null,
        );
      } catch (e) {
        throw FileSystemException(e.toString());
      }
    }

    Directory(p.joinAll([parentDirectory.absolute.path, storeName]))
        .createSync(recursive: true);

    if (behavior == CacheBehavior.onlineOnly)
      return ntfi(true, false);
    else if (behavior == CacheBehavior.cacheOnly)
      return ntfi(false, true);
    else {
      if (behavior == CacheBehavior.cacheRenew ||
          (!cachedValidDuration.isNegative &&
              fileReal.existsSync() &&
              DateTime.now().millisecondsSinceEpoch -
                      fileReal.lastModifiedSync().millisecondsSinceEpoch >
                  cachedValidDuration.inMilliseconds))
        File(
          p.joinAll([
            parentDirectory.absolute.path,
            storeName,
            getTileUrl(coords, options)
                .replaceAll('https://', '')
                .replaceAll('http://', '')
                .replaceAll("/", ""),
            //.replaceAll(".", "")
          ]),
        ).deleteSync();
      return ntfi(true, true);
    }
  }

  //! MAIN DOWNLOAD FUNCTIONS !//

  /// Download a specified `DownloadableRegion` in the foreground
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use `checkRegion()`.
  ///
  /// Unless otherwise specified, also starts a recovery session.
  ///
  /// Streams a `DownloadProgress` object containing the number of completed tiles, total number of tiles to download, a list of errored URLs and the percentage completion.
  Stream<DownloadProgress> downloadRegion(
    DownloadableRegion region, {
    bool disableRecovery = false,
  }) async* {
    if (!disableRecovery) {
      if (!MapCachingManager(parentDirectory, storeName).startRecovery(
        region.type,
        region.originalRegion,
        region.minZoom,
        region.maxZoom,
        region.seaTileRemoval,
        region.compressionQuality,
      ))
        throw StateError(
            'Failed to create recovery session. Restart app and retry. If issue persists, disable recovery to continue.');
      _downloadOngoing = true;
    }
    if (region.type == RegionType.circle) {
      yield* _spawnDownloadIsolate(
        region,
        await compute(
          _circleTiles,
          {
            'circleOutline': region.points,
            'minZoom': region.minZoom,
            'maxZoom': region.maxZoom,
            'crs': region.crs,
            'tileSize':
                CustomPoint(region.options.tileSize, region.options.tileSize),
          },
        ),
      );
    } else if (region.type == RegionType.rectangle) {
      yield* _spawnDownloadIsolate(
        region,
        await compute(
          _rectangleTiles,
          {
            'bounds': LatLngBounds.fromPoints(region.points),
            'minZoom': region.minZoom,
            'maxZoom': region.maxZoom,
            'crs': region.crs,
            'tileSize':
                CustomPoint(region.options.tileSize, region.options.tileSize),
          },
        ),
      );
    } else if (region.type == RegionType.line) {
      print(
        '\nCAUTION\nThis functionality is highly experimental and should not be used unless otherwise necessary. This functionality is likely to fail.\n',
      );
      yield* _downloadLine(
        region.points,
        region.minZoom,
        region.maxZoom,
        region.options,
        preventRedownload: region.preventRedownload,
        seaTileRemoval: region.seaTileRemoval,
        compressionQuality: region.compressionQuality,
        crs: region.crs,
        errorHandler: region.errorHandler,
      );
    }
  }

  /// Check approximately how many downloadable tiles are within a specified `DownloadableRegion`
  ///
  /// This does not take into account sea tile removal or redownload prevention, as these are handled in the download portion of the code.
  ///
  /// Returns an `int` which is the number of tiles.
  static Future<int> checkRegion(DownloadableRegion region) async {
    if (region.type == RegionType.circle)
      return (await compute(
        _circleTiles,
        {
          'circleOutline': region.points,
          'minZoom': region.minZoom,
          'maxZoom': region.maxZoom,
          'crs': region.crs,
          'tileSize':
              CustomPoint(region.options.tileSize, region.options.tileSize),
        },
      ))
          .length;
    else if (region.type == RegionType.rectangle)
      return (await compute(
        _rectangleTiles,
        {
          'bounds': LatLngBounds.fromPoints(region.points),
          'minZoom': region.minZoom,
          'maxZoom': region.maxZoom,
          'crs': region.crs,
          'tileSize':
              CustomPoint(region.options.tileSize, region.options.tileSize),
        },
      ))
          .length;
    else
      throw UnimplementedError(
        'This functionality is not yet supported, as the main part is experimental and this part has not been completed yet',
      );
  }

  /// Cancels the ongoing foreground download and recovery session (within the current object)
  ///
  /// Will throw errors if there is no ongoing download. Do not use to cancel background downloads, return `true` from the background download callback to cancel a background download.
  void cancelDownload() {
    _isolate.kill();
    _receivePort.close();
    MapCachingManager(parentDirectory, storeName).endRecovery();
    _downloadOngoing = false;
  }

  /// Recover a download that has been stopped without the correct methods, for example after closing the app during a download
  ///
  /// Returns `null` if there is no recoverable download, otherwise returns a `RecoveredRegion` containing the salvaged data. Use `.toDownloadable()` on the region to recieve a `DownloadableRegion`, which can be passed normally to other functions.
  ///
  /// Optionally make `deleteRecovery` `false` if you would like the download to still be recoverable after this method has been called.
  ///
  /// How does recovery work? At the start of a download, a file is created including information about the download. At the end of a download or when a download is correctly cancelled, this file is deleted. However, if there is no ongoing download (controlled by an internal variable) and the recovery file exists, the download has obviously been stopped incorrectly, meaning it can be recovered using the information within the recovery file.
  RecoveredRegion? recoverDownload({bool deleteRecovery = true}) {
    if (_downloadOngoing) return null;

    final RecoveredRegion? recovered =
        MapCachingManager(parentDirectory, storeName).recoverDownload();

    if (recovered == null) return null;

    if (deleteRecovery)
      MapCachingManager(parentDirectory, storeName).endRecovery();
    return recovered;
  }

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
    if (Platform.isAndroid) {
      final PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied || status.isLimited) {
        final PermissionStatus statusAfter =
            await Permission.ignoreBatteryOptimizations.request();
        if (statusAfter.isGranted) return true;
        return false;
      } else if (status.isGranted)
        return true;
      else
        return false;
    } else
      throw UnsupportedError(
          'The background download feature is only available on Android due to limitations with other operating systems.');
  }

  /// Download a specified `DownloadableRegion` in the background, and show a notification progress bar (by default)
  ///
  /// The statistics may move 'all over the place', especially on larger downloads, due to the `Isolate` working: this is unavoidable with the new system since v4.0.0.
  ///
  /// Only available on Android devices, due to limitations with other operating systems. Downloading in the the background is likely to be slower and/or less stable than downloading in the foreground.
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use `checkRegion()`.
  ///
  /// You may want to call `requestIgnoreBatteryOptimizations()` beforehand, depending on how/where/why this background download will be used. See documentation on that method for more information.
  ///
  /// Optionally specify `showNotification` as `false` to disable the built-in notification system.
  ///
  /// Optionally specify a `callback` that gets fired every time another tile is downloaded/failed, takes one `DownloadProgress` argument, and returns a boolean. Download can be cancelled by returning `true` from `callback` function or by fully closing the app.
  ///
  /// Always starts a recovery session.
  ///
  /// If the download doesn't seem to start on a testing device, try changing `useAltMethod` to `true`. This will switch to an older Android API, so should only be used if it is the most stable on a device. You may be able to programatically detect if the download hasn't started by using the callback, therefore allowing you to call this method again with `useAltMethod`, but this isn't guranteed.
  ///
  /// Returns nothing.
  void downloadRegionBackground(
    DownloadableRegion region, {
    bool showNotification = true,
    bool Function(DownloadProgress)? callback,
    bool useAltMethod = false,
    String notificationChannelName = 'Map Background Downloader',
    String notificationChannelDescription =
        'Displays progress notifications to inform the user about the progress of their map download.',
    String subText = 'Map Downloader',
    String ongoingTitle = 'Map Downloading...',
    String Function(DownloadProgress)? ongoingBodyBuilder,
    String cancelledTitle = 'Map Download Cancelled',
    String Function(DownloadProgress)? cancelledBodyBuilder,
    String completeTitle = 'Map Downloaded',
    String Function(DownloadProgress)? completeBodyBuilder,
  }) async {
    if (Platform.isAndroid) {
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
                notificationChannelName,
                channelDescription: notificationChannelDescription,
                showProgress: true,
                maxProgress: event.maxTiles,
                progress: event.attemptedTiles,
                visibility: NotificationVisibility.public,
                subText: subText,
                importance: Importance.low,
                priority: Priority.low,
                showWhen: false,
                playSound: false,
                enableLights: false,
                enableVibration: false,
                onlyAlertOnce: true,
                autoCancel: false,
              );
              NotificationDetails platformChannelSpecifics =
                  NotificationDetails(android: androidPlatformChannelSpecifics);
              if (showNotification) {
                await flutterLocalNotificationsPlugin!.show(
                  0,
                  ongoingTitle,
                  ongoingBodyBuilder == null
                      ? '${event.attemptedTiles}/${event.maxTiles} (${event.percentageProgress.round().toString()}%)'
                      : ongoingBodyBuilder(event),
                  platformChannelSpecifics,
                );
              }

              if (callback != null && callback(event)) {
                sub!.cancel();
                cancelDownload();
                if (showNotification) {
                  flutterLocalNotificationsPlugin!.cancel(0);
                  await flutterLocalNotificationsPlugin.show(
                    0,
                    cancelledTitle,
                    cancelledBodyBuilder == null
                        ? '${event.remainingTiles} tiles remained'
                        : cancelledBodyBuilder(event),
                    platformChannelSpecifics,
                  );
                }
                BackgroundFetch.finish(taskId);
              }

              if (event.percentageProgress == 100) {
                sub!.cancel();
                if (showNotification) {
                  flutterLocalNotificationsPlugin!.cancel(0);
                  await flutterLocalNotificationsPlugin.show(
                    0,
                    completeTitle,
                    completeBodyBuilder == null
                        ? '${event.failedTiles.length} failed tiles'
                        : completeBodyBuilder(event),
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

  //! STANDARD FUNCTIONS !//

  Stream<DownloadProgress> _spawnDownloadIsolate(
    DownloadableRegion region,
    List<Coords<num>> tiles,
  ) async* {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_downloadIsolate, {
      'port': _receivePort.sendPort,
      'region': region,
      'parentDirectory': parentDirectory,
      'storeName': storeName,
      'tiles': tiles,
    });
    await for (DownloadProgress evt in _receivePort) {
      yield evt;
      if (evt.percentageProgress == 100) cancelDownload();
    }
  }

  static _downloadIsolate(Map<String, dynamic> input) async {
    final DownloadableRegion region = input['region'];

    await for (DownloadProgress progress in _downloadLoop(
      input['parentDirectory'],
      input['storeName'],
      input['tiles'],
      region.options,
      region.preventRedownload,
      region.seaTileRemoval,
      region.compressionQuality,
      region.errorHandler,
    )) input['port'].send(progress);
  }

  static Stream<List> _downloadBulkFiles({
    required tiles,
    required parentDirectory,
    required storeName,
    required provider,
    required options,
    required client,
    required errorHandler,
    required preventRedownload,
    required seaTileBytes,
    required compressionQuality,
  }) {
    int successfulTiles = 0;
    List<String> failedTiles = [];
    int seaTiles = 0;
    int existingTiles = 0;

    final StreamController<List> streamController = StreamController();
    final queue = Queue(parallel: maxParallel);

    tiles.forEach((e) {
      queue
          .add(() => _getAndSaveTile(
                parentDirectory,
                storeName,
                provider,
                e,
                options,
                client,
                errorHandler,
                preventRedownload,
                seaTileBytes,
                compressionQuality,
              ))
          .then((value) {
        try {
          successfulTiles += value[0] as int;
          if (value[1].isNotEmpty) failedTiles.add(value[1]);
          seaTiles += value[2] as int;
          existingTiles += value[3] as int;
        } catch (e) {}
        streamController.add([
          value[0],
          value[1],
          value[2],
          value[3],
        ]);
      });
    });

    return streamController.stream;
  }

  static Stream<DownloadProgress> _downloadLoop(
      CacheDirectory parentDirectory,
      String storeName,
      List<Coords<num>> tiles,
      TileLayerOptions options,
      bool preventRedownload,
      bool seaTileRemoval,
      int compressionQuality,
      Function(dynamic)? errorHandler) async* {
    final http.Client client = http.Client();
    Directory(p.joinAll([parentDirectory.absolute.path, storeName]))
        .createSync(recursive: true);

    Uint8List? seaTileBytes;
    if (seaTileRemoval)
      seaTileBytes = (await client
              .get(Uri.parse('https://tile.openstreetmap.org/19/0/0.png')))
          .bodyBytes;

    final StorageCachingTileProvider provider = StorageCachingTileProvider(
        parentDirectory: parentDirectory, storeName: storeName);

    int successfulTiles = 0;
    List<String> failedTiles = [];
    int seaTiles = 0;
    int existingTiles = 0;
    final DateTime startTime = DateTime.now();

    final Stream<List<dynamic>> returned = _downloadBulkFiles(
      tiles: tiles,
      parentDirectory: parentDirectory,
      storeName: storeName,
      provider: provider,
      options: options,
      client: client,
      errorHandler: errorHandler,
      preventRedownload: preventRedownload,
      seaTileBytes: seaTileBytes,
      compressionQuality: compressionQuality,
    );

    await for (final event in returned) {
      successfulTiles += event[0] as int;
      if (event[1] != '') failedTiles.add(event[1]);
      seaTiles += event[2] as int;
      existingTiles += event[3] as int;

      yield DownloadProgress(
        maxTiles: tiles.length,
        successfulTiles: successfulTiles,
        failedTiles: failedTiles,
        seaTiles: seaTiles,
        existingTiles: existingTiles,
        duration: DateTime.now().difference(startTime),
      );
    }

    client.close();
  }

  static Future<List<dynamic>> _getAndSaveTile(
    CacheDirectory parentDirectory,
    String storeName,
    StorageCachingTileProvider provider,
    Coords<num> coord,
    TileLayerOptions options,
    http.Client client,
    Function(dynamic)? errorHandler,
    bool preventRedownload,
    Uint8List? seaTileBytes,
    int compressionQuality,
  ) async {
    final Coords<double> coordDouble =
        Coords(coord.x.toDouble(), coord.y.toDouble())..z = coord.z.toDouble();
    final String url = provider.getTileUrl(coordDouble, options);
    final String path = p.joinAll([
      parentDirectory.absolute.path,
      storeName,
      url
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll("/", ""),
      //.replaceAll(".", ""),
    ]);

    try {
      if (preventRedownload && File(path).existsSync()) return [1, '', 0, 1];

      File(path).writeAsBytesSync(
        (await client.get(Uri.parse(url))).bodyBytes,
        flush: true,
      );

      if (seaTileBytes != null &&
          ListEquality().equals(File(path).readAsBytesSync(), seaTileBytes)) {
        File(path).deleteSync();
        return [1, '', 1, 0];
      }

      if (compressionQuality != -1) {
        final Uint8List? compressed =
            await FlutterImageCompress.compressWithFile(
          path,
          quality: compressionQuality,
          autoCorrectionAngle: false,
          format:
              url.endsWith('.png') ? CompressFormat.png : CompressFormat.jpeg,
          minHeight: options.tileSize.round(),
          minWidth: options.tileSize.round(),
        );

        File(path).writeAsBytesSync(compressed ?? [0]);
      }
    } catch (e) {
      if (errorHandler != null) errorHandler(e);
      return [0, url, 0, 0];
    }

    return [1, '', 0, 0];
  }

  //!   LINE FUNCTIONS    !//
  //! HIGHLY EXPERIMENTAL !//

  static List<Coords<num>> _lineTiles(
    List<List<List<dynamic>>> rectsOverall,
    int minZoom,
    int maxZoom, {
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  }) {
    final List<Coords<num>> coords = [];

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      final List<List<LatLng>> rects =
          rectsOverall[zoomLvl] as List<List<LatLng>>;
      rects.forEach((rect) {
        rect.forEach((point) {
          rectsOverall[zoomLvl][rects.indexOf(rect)][rect.indexOf(point)] = crs
              .latLngToPoint(point, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .floor();
        });
      });
    }

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      final List<List<CustomPoint<num>>> rects =
          rectsOverall[zoomLvl] as List<List<CustomPoint<num>>>;
      rects.forEach((rect) {
        rect.forEach((node) {
          coords.add(
            Coords(node.x.toDouble(), node.y.toDouble())
              ..z = zoomLvl.toDouble(),
          );
          print(node);
        });
      });
    }

    return coords;
    /*final Map<int, Map<int, List<int>>> outlineTileNums = {};

    final List<Coords<num>> coords = [];

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};

      for (LatLng node in lineOutline) {
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

    return coords;*/
  }

  Stream<DownloadProgress> _downloadLine(
    List<LatLng> basicRectOutlines,
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    int compressionQuality = -1,
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
  }) async* {
    /*double calcDist(LatLng a, LatLng b) {
      final double p = 0.017453292519943295;
      final double formula = 0.5 -
          math.cos((b.latitude - a.latitude) * p) / 2 +
          math.cos(a.latitude * p) *
              math.cos(b.latitude * p) *
              (1 - math.cos((b.longitude - a.longitude) * p)) /
              2;
      return 12742 * math.asin(math.sqrt(formula)) * 1000;
    }*/

    final List<List<LatLng>> rects = [];
    for (int pos = 0; pos < basicRectOutlines.length; pos + 4) {
      rects.insert(pos, [
        basicRectOutlines[pos],
        basicRectOutlines[pos + 1],
        basicRectOutlines[pos + 2],
        basicRectOutlines[pos + 3],
      ]);
    }
    print(rects);

    final List<List<List<LatLng>>> realRectsPerZoom =
        List.generate(rects.length, (index) => [[]]);

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      rects.forEach((rect) {
        for (int ii = 0; ii < rect.length; ii++) {
          final LatLng a = rect[ii];
          final LatLng b = rect[(ii + 1) > rect.length - 1 ? 0 : (ii + 1)];
          final double resolution = (40075.016686 * 1000 / 256) *
              math.cos((a.latitude + b.latitude) / 2) /
              (2 ^ zoomLvl);
          for (double dist = 0; dist <= a >> b; dist += resolution) {
            realRectsPerZoom[zoomLvl][rects.indexOf(rect)]
                .add(Distance().offset(a, dist, Distance().bearing(a, b)));
          }
        }
      });
    }

    print(realRectsPerZoom);

    final List<Coords<num>> tiles = _lineTiles(
      realRectsPerZoom,
      minZoom,
      maxZoom,
      crs: crs,
      tileSize: CustomPoint(options.tileSize, options.tileSize),
    );

    /*yield* _downloadLoop(
      tiles,
      options,
      preventRedownload,
      seaTileRemoval,
      compressionQuality,
      errorHandler,
    );*/
  }
}

//! TILE LOOPS !//

List<Coords> _rectangleTiles(Map<String, dynamic> input) {
  final LatLngBounds bounds = input['bounds'];
  final int minZoom = input['minZoom'];
  final int maxZoom = input['maxZoom'];
  final Crs crs = input['crs'];
  final CustomPoint<num> tileSize = input['tileSize'];

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

List<Coords<num>> _circleTiles(Map<String, dynamic> input) {
  final List<LatLng> circleOutline = input['circleOutline'];
  final int minZoom = input['minZoom'];
  final int maxZoom = input['maxZoom'];
  final Crs crs = input['crs'];
  final CustomPoint<num> tileSize = input['tileSize'];

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
