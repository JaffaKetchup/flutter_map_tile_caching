// TODO: Implement precise recovery
// TODO: Battery and Internet checks

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:background_fetch/background_fetch.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_info/enums/charging_status.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path/path.dart' as p show joinAll;
import 'package:permission_handler/permission_handler.dart';
import 'package:queue/queue.dart';

import 'bulkDownload/downloadProgress.dart';
import 'bulkDownload/tileLoops.dart';
import 'misc.dart';
import 'regions/downloadableRegion.dart';
import 'regions/recoveredRegion.dart';
import 'storageManager.dart';

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

  /// The directory to place cache stores into
  ///
  /// Use `await MapStorageManager.normalDirectory` wherever possible, or `await MapStorageManager.temporaryDirectory` alternatively (see documentation). If creating a path manually, be sure it's the correct format, use the `path` library if needed.
  ///
  /// Required.
  final CacheDirectory parentDirectory;

  /// The name of the cache store to use for this instance
  ///
  /// Defaults to the default store, 'mainStore'.
  final String storeName;

  /// The behavior method to get the tile
  ///
  /// Defaults to `cacheFirst` - get tiles from the local cache, going online to update the cache if `cachedValidDuration` has passed.
  final CacheBehavior behavior;

  /// The duration until a tile expires and needs to be fetched again when browsing
  ///
  /// Several internal limitations mean this functionality is accomplished by deleting the tile before getting it from the Internet again. Therefore, this only has an effect when `behavior` is set to `cacheFirst`.
  ///
  /// Note that if the tile cannot be loaded from the Internet again, the tile will fail to load even if the tile was in the cache before: for this reason set `behavior` to `cacheOnly` if the user is offline or in 'an offline mode'.
  ///
  /// Defaults to 16 days, set to `Duration.zero` to disable.
  final Duration cachedValidDuration;

  /// The maximum number of tiles allowed in a cache store (only whilst 'browsing' - see below) before the oldest tile gets deleted
  ///
  /// Only applies to 'browse caching', ie. downloading regions will bypass this limit. Please note that this can be computationally expensive as it potentially involves sorting through this many files to find the oldest file.
  ///
  /// Defaults to 20000, set to 0 to disable.
  final int maxStoreLength;

  bool _downloadOngoing = false; // Used internally for recovery purposes
  Queue? _queue; // Used to download tiles in bulk
  StreamController<List>? _streamController; // Used to control bulk downloading

  /// Create a `TileProvider` to automatically cache browsed (panned over) tiles to a local caching database. Also contains methods to download regions of a map to a local caching database using an instance.
  ///
  /// Optionally pass a vaild cache duration to override the default 31 days, or pass the name of a cache store to use it instead of the default.
  ///
  /// See online documentation for more information about the caching/downloading behaviour of this library.
  StorageCachingTileProvider({
    required this.parentDirectory,
    this.storeName = 'mainStore',
    this.behavior = CacheBehavior.cacheFirst,
    this.cachedValidDuration = const Duration(days: 16),
    this.maxStoreLength = 20000,
  });

  //! TILE PROVIDER !//

  /// Get a browsed tile as an image, paint it on the map and save it's bytes to cache for later
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final String url = getTileUrl(coords, options);
    final Directory store =
        Directory(p.joinAll([parentDirectory.absolute.path, storeName]));
    store.createSync();
    final File file = File(
      p.joinAll([
        store.absolute.path,
        url
            .replaceAll('https://', '')
            .replaceAll('http://', '')
            .replaceAll("/", "")
            .replaceAll(".", ""),
      ]),
    );

    final List<FileSystemEntity> fileList = store.listSync();

    if (fileList.length > maxStoreLength) {
      fileList.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      fileList.last.deleteSync();
    }

    if (behavior == CacheBehavior.cacheFirst &&
        cachedValidDuration != Duration.zero &&
        file.existsSync() &&
        DateTime.now().millisecondsSinceEpoch -
                file.lastModifiedSync().millisecondsSinceEpoch >
            cachedValidDuration.inMilliseconds) file.deleteSync();

    try {
      return NetworkToFileImage(
        url: behavior == CacheBehavior.cacheOnly ? null : url,
        file: behavior == CacheBehavior.onlineOnly ? null : file,
      );
    } catch (e) {}

    throw FallThroughError();
  }

  //! GENERAL DOWNLOADING STARTS !//

  /// Download a specified `DownloadableRegion` in the foreground
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use `checkRegion()`.
  ///
  /// Unless otherwise specified, also starts a recovery session. Enabling 'specific recovery' will slow download, but will allow a download to start again at the correct tile instead of having to start from the beginning. Leaving `specificRecovery` as `false` will mean a recovered download will have to restart.
  ///
  /// Use `preDownloadChecksCallback` to ensure the download is good to go. Setting this to `null` will skip all checks, and is not recommended. Otherwise, the function must take a `ConnectivityResult` representing the status of the Internet connection, a nullable-integer representing the battery/charge level of the device if readable, and a nullable-`ChargingStatus` representing the charging status of the device if readable. The function must be asynchronus (to allow for asking the user through something like a dialog box) and return either `null` representing 'do default', `true` representing 'let the download continue', or `false` representing 'cancel the download'. The 'default' is to cancel the download if the user is on cellular data, disconnected, or under 15% charge and not connected to a power source. See below to see how to check if the checks fail.
  ///
  /// Useful simple ideas for `preDownloadChecksCallback`:
  ///
  /// 1. Do default
  /// ```dart
  /// preDownloadChecksCallback: (_, __, ___) async => null
  /// ```
  ///
  /// 2. Only consider battery
  /// ```dart
  /// preDownloadChecksCallback: (_, lvl, status) async => lvl! > 15 || status == ChargingStatus.Charging
  /// ```
  ///
  /// 3. Only consider connectivity
  /// ```dart
  /// preDownloadChecksCallback: (c, _, __) async => c == ConnectivityResult.wifi || c == ConnectivityResult.ethernet
  /// ```
  ///
  /// 4. Check if the checks have failed
  /// ```dart
  /// final Stream<DownloadProgress> downloadStream = downloadRegion(...);
  /// if (await downloadStream.isEmpty) "<checks have failed>"
  /// else "<checks have passed, listen to stream>"
  /// ```
  ///
  /// Streams a `DownloadProgress` object containing lots of handy information about the download's progression status; unless the pre-download checks fail, in which case the stream's `.isEmpty` will be `true`. If you get messages about 'Bad State' after dealing with the checks, just add `.asBroadcastStream()` on the end of `downloadRegion()`.
  Stream<DownloadProgress> downloadRegion(
    DownloadableRegion region, {
    bool disableRecovery = false,
    bool specificRecovery = false,
    required Future<bool?> Function(ConnectivityResult, int?, ChargingStatus?)?
        preDownloadChecksCallback,
  }) async* {
    if (preDownloadChecksCallback != null) {
      final ConnectivityResult connectivity =
          await Connectivity().checkConnectivity();

      late final int? batteryLevel;
      late final ChargingStatus? chargingStatus;
      if (Platform.isAndroid) {
        final _info = await BatteryInfoPlugin().androidBatteryInfo;
        batteryLevel = _info?.batteryLevel;
        chargingStatus = _info?.chargingStatus;
      } else if (Platform.isIOS) {
        final _info = await BatteryInfoPlugin().iosBatteryInfo;
        batteryLevel = _info?.batteryLevel;
        chargingStatus = _info?.chargingStatus;
      } else
        throw FallThroughError();

      final bool? result = await preDownloadChecksCallback(
          connectivity, batteryLevel, chargingStatus);

      if ((result == null &&
              (connectivity == ConnectivityResult.mobile ||
                  connectivity == ConnectivityResult.none ||
                  !((batteryLevel ?? 50) > 15 ||
                      chargingStatus == ChargingStatus.Charging))) ||
          result == false) {
        return;
      }
    }

    if (!disableRecovery) {
      if (!MapCachingManager(parentDirectory, storeName).startRecovery(
        region.type,
        region.originalRegion,
        region.minZoom,
        region.maxZoom,
        region.preventRedownload,
        region.seaTileRemoval,
      ))
        throw StateError(
            'Failed to create recovery session. Restart app and retry. If issue persists, disable recovery to continue.');
      _downloadOngoing = true;
    }

    _queue = Queue(parallel: region.parallelThreads);
    _streamController = StreamController();

    yield* _startDownload(
      region: region,
      tiles: await compute(
        region.type == RegionType.rectangle
            ? rectangleTiles
            : region.type == RegionType.circle
                ? circleTiles
                : lineTiles,
        {
          'bounds': LatLngBounds.fromPoints(region.points),
          'circleOutline': region.points,
          'lineOutline': region.points.chunked(4),
          'minZoom': region.minZoom,
          'maxZoom': region.maxZoom,
          'crs': region.crs,
          'tileSize':
              CustomPoint(region.options.tileSize, region.options.tileSize),
        },
      ),
    );
  }

  /// Check approximately how many downloadable tiles are within a specified `DownloadableRegion`
  ///
  /// This does not take into account sea tile removal or redownload prevention, as these are handled in the download portion of the code. Specific recovery is also ignored.
  ///
  /// Returns an `int` which is the number of tiles.
  static Future<int> checkRegion(DownloadableRegion region) async =>
      (await compute(
        region.type == RegionType.rectangle
            ? rectangleTiles
            : region.type == RegionType.circle
                ? circleTiles
                : lineTiles,
        {
          'bounds': LatLngBounds.fromPoints(region.points),
          'circleOutline': region.points,
          'lineOutline': region.points.chunked(4),
          'minZoom': region.minZoom,
          'maxZoom': region.maxZoom,
          'crs': region.crs,
          'tileSize':
              CustomPoint(region.options.tileSize, region.options.tileSize),
        },
      ))
          .length;

  /// Cancels the ongoing foreground download and recovery session (within the current object)
  ///
  /// Will throw errors if there is no ongoing download. Do not use to cancel background downloads, return `true` from the background download callback to cancel a background download.
  void cancelDownload() {
    _queue?.dispose();
    _streamController?.close();
    MapCachingManager(parentDirectory, storeName).endRecovery();
    _downloadOngoing = false;
  }

  /// Recover a download that has been stopped without the correct methods, for example after closing the app during a download
  ///
  /// Returns `null` if there is no recoverable download, otherwise returns a `RecoveredRegion` containing the salvaged data. Use `.toDownloadable()` on the region to recieve a `DownloadableRegion`, which can be passed normally to other functions.
  ///
  /// Optionally make `deleteRecovery` `false` if you would like the download to still be recoverable after this method has been called.
  ///
  /// How does recovery work? At the start of a download, a file is created including information about the download. At the end of a download or when a download is correctly cancelled, this file is deleted. However, if there is no ongoing download (controlled by an internal variable) and the recovery file exists, the download has obviously been stopped incorrectly, meaning it can be recovered using the information within the recovery file. If specific recovery was enabled, this download can be resumed from the last known tile number (stored alongside the recovery file), otherwise the download must start from the beginning.
  RecoveredRegion? recoverDownload({bool deleteRecovery = true}) {
    if (_downloadOngoing) return null;

    final RecoveredRegion? recovered =
        MapCachingManager(parentDirectory, storeName).recoverDownload();

    if (recovered == null) return null;

    if (deleteRecovery)
      MapCachingManager(parentDirectory, storeName).endRecovery();

    return recovered;
  }

  //! BACKGROUND DOWNLOADING STARTS*/

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
  /// Always starts a specific recovery session.
  ///
  /// If the download doesn't seem to start on a device, try changing `useAltMethod` to `true`. This will switch to an older Android API, so should only be used if it is the most stable on a device. You may be able to programatically detect if the download hasn't started by using the callback, therefore allowing you to call this method again with `useAltMethod`, but this isn't guranteed.
  ///
  /// See `downloadRegion(...)` for an explanation and examples of `preDownloadChecksCallback`. `preDownloadChecksFailedCallback` is optional and will be called if the checks do fail, after cancelling the download.
  ///
  /// Returns nothing.
  void downloadRegionBackground(
    DownloadableRegion region,
    StorageCachingTileProvider provider, {
    bool showNotification = true,
    bool Function(DownloadProgress)? callback,
    required Future<bool?> Function(ConnectivityResult, int?, ChargingStatus?)?
        preDownloadChecksCallback,
    void Function()? preDownloadChecksFailedCallback,
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
            final download = downloadRegion(
              region,
              specificRecovery: true,
              preDownloadChecksCallback: preDownloadChecksCallback,
            );
            if (await download.isEmpty) {
              cancelDownload();
              if (preDownloadChecksFailedCallback != null)
                preDownloadChecksFailedCallback();
              BackgroundFetch.finish(taskId);
              return;
            }

            sub = download.listen((event) async {
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
                cancelDownload();
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
        (String taskId) async => BackgroundFetch.finish(taskId),
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

  //! DOWNLOAD FUNCTIONS !//

  Stream<DownloadProgress> _startDownload({
    required DownloadableRegion region,
    required List<Coords<num>> tiles,
  }) async* {
    final http.Client client = http.Client();
    Directory(p.joinAll([parentDirectory.absolute.path, storeName]))
        .createSync(recursive: true);

    Uint8List? seaTileBytes;
    if (region.seaTileRemoval)
      seaTileBytes = (await client.get(
        Uri.parse(this.getTileUrl(Coords(0, 0)..z = 19, region.options)),
      ))
          .bodyBytes;

    int successfulTiles = 0;
    List<String> failedTiles = [];
    int seaTiles = 0;
    int existingTiles = 0;
    final DateTime startTime = DateTime.now();

    assert(
      !(_queue?.isCancelled ?? true),
      'The download function has not been called properly and the `Queue` object does not exist yet or has been cancelled. Try again.',
    );
    assert(
      !(_streamController?.isClosed ?? true),
      'The download function has not been called properly and the `StreamController` object does not exist yet or has been cancelled. Try again.',
    );

    final Stream<List<dynamic>> downloadStream = _bulkDownloader(
      tiles: tiles,
      parentDirectory: parentDirectory,
      storeName: storeName,
      provider: this,
      options: region.options,
      client: client,
      parallelThreads: region.parallelThreads,
      errorHandler: region.errorHandler,
      preventRedownload: region.preventRedownload,
      seaTileBytes: seaTileBytes,
      queue: _queue!,
      streamController: _streamController!,
    );

    await for (List<dynamic> event in downloadStream) {
      successfulTiles += event[0] as int;
      if (event[1] != '') failedTiles.add(event[1]);
      seaTiles += event[2] as int;
      existingTiles += event[3] as int;

      final DownloadProgress prog = DownloadProgress(
        maxTiles: tiles.length,
        successfulTiles: successfulTiles,
        failedTiles: failedTiles,
        seaTiles: seaTiles,
        existingTiles: existingTiles,
        duration: DateTime.now().difference(startTime),
      );
      yield prog;
      if (prog.percentageProgress >= 100) cancelDownload();
    }

    client.close();
  }

  static Stream<List> _bulkDownloader({
    required List<Coords<num>> tiles,
    required Directory parentDirectory,
    required String storeName,
    required StorageCachingTileProvider provider,
    required TileLayerOptions options,
    required http.Client client,
    required Function(dynamic)? errorHandler,
    required int parallelThreads,
    required bool preventRedownload,
    required Uint8List? seaTileBytes,
    required Queue queue,
    required StreamController<List> streamController,
  }) {
    tiles.forEach((e) {
      if (!queue.isCancelled)
        queue
            .add(
          () => _getAndSaveTile(
            parentDirectory,
            storeName,
            provider,
            e,
            options,
            client,
            errorHandler,
            preventRedownload,
            seaTileBytes,
          ),
        )
            .then(
          (value) {
            if (!streamController.isClosed)
              streamController.add(
                [
                  value[0],
                  value[1],
                  value[2],
                  value[3],
                ],
              );
          },
        );
    });

    return streamController.stream;
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
          .replaceAll("/", "")
          .replaceAll(".", ""),
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
    } catch (e) {
      if (errorHandler != null) errorHandler(e);
      return [0, url, 0, 0];
    }

    return [1, '', 0, 0];
  }
}
