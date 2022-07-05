// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:background_fetch/background_fetch.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_info/enums/charging_status.dart';
import 'package:battery_info/model/android_battery_info.dart';
import 'package:battery_info/model/iso_battery_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:queue/queue.dart';

import '../bulk_download/download_progress.dart';
import '../bulk_download/downloader.dart';
import '../bulk_download/tile_loops.dart';
import '../bulk_download/tile_progress.dart';
import '../internal/tile_provider.dart';
import '../misc/typedefs.dart';
import '../regions/downloadable_region.dart';
import '../settings/tile_provider_settings.dart';
import 'directory.dart';

/// Provides tools to manage bulk downloading to a specific [StoreDirectory]
class DownloadManagement {
  /// The store directory to provide access paths to
  final StoreDirectory _storeDirectory;

  /// Used internally to queue download tiles to process in bulk
  Queue? _queue;

  /// Used internally to keep track of the recovery file
  int? _recoveryId;

  /// Used internally to control bulk downloading
  StreamController<TileProgress>? _streamController;

  /// Provides tools to manage bulk downloading to a specific [StoreDirectory]
  DownloadManagement(this._storeDirectory);

  /// Download a specified [DownloadableRegion] in the foreground
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use [check].
  ///
  /// Unless otherwise specified, also starts a recovery session.
  ///
  /// _[preDownloadChecksCallback] has been deprecated without replacement or alternative. Usage will continue to function until the next minor release, at which time this functionality will be removed._
  ///
  /// Streams a [DownloadProgress] object containing lots of handy information about the download's progression status; unless the pre-download checks fail, in which case the stream's `.isEmpty` will be `true` and no new events will be emitted. If you get messages about 'Bad State' after dealing with the checks, just add `.asBroadcastStream()` on the end of [startForeground].
  Stream<DownloadProgress> startForeground({
    required DownloadableRegion region,
    FMTCTileProviderSettings? tileProviderSettings,
    bool disableRecovery = false,
    @Deprecated(
      '`preDownloadChecksCallback` has been deprecated without replacement or alternative. Usage will continue to function until the next minor release, at which time this functionality will be removed.',
    )
        PreDownloadChecksCallback preDownloadChecksCallback,
  }) async* {
    if (preDownloadChecksCallback != null) {
      final ConnectivityResult connectivity =
          await Connectivity().checkConnectivity();

      late final int? batteryLevel;
      late final ChargingStatus? chargingStatus;
      if (Platform.isAndroid) {
        final AndroidBatteryInfo? info =
            await BatteryInfoPlugin().androidBatteryInfo;
        batteryLevel = info?.batteryLevel;
        chargingStatus = info?.chargingStatus;
      } else if (Platform.isIOS) {
        final IosBatteryInfo? info = await BatteryInfoPlugin().iosBatteryInfo;
        batteryLevel = info?.batteryLevel;
        chargingStatus = info?.chargingStatus;
      } else {
        throw FallThroughError();
      }

      final bool? result = await preDownloadChecksCallback(
        connectivity,
        batteryLevel,
        chargingStatus,
      );

      if ((result == null &&
              (connectivity == ConnectivityResult.mobile ||
                  connectivity == ConnectivityResult.none ||
                  !((batteryLevel ?? 50) > 15 ||
                      chargingStatus == ChargingStatus.Charging))) ||
          result == false) {
        return;
      }
    }

    _recoveryId = hashValues(
          region,
          tileProviderSettings,
          _storeDirectory.getTileProvider(tileProviderSettings),
        ) *
        DateTime.now().millisecondsSinceEpoch;

    if (!disableRecovery) {
      await _storeDirectory.rootDirectory.recovery.start(
        id: _recoveryId!,
        description:
            '${_storeDirectory.storeName}: ${region.type.name[0].toUpperCase() + region.type.name.substring(1)} Type',
        region: region,
        storeDirectory: _storeDirectory,
      );
    }

    _queue = Queue(parallel: region.parallelThreads);
    _streamController = StreamController();

    yield* _startDownload(
      tileProviderSettings: tileProviderSettings,
      region: region,
      tiles: await _generateTilesComputer(region),
    );
  }

  /// Download a specified [DownloadableRegion] in the background, and show a notification progress bar (by default)
  ///
  /// Only available on Android devices, due to limitations with other operating systems. Background downloading is complicated: see the documentation website for more information.
  ///
  /// You may want to call [requestIgnoreBatteryOptimizations] beforehand, depending on how/where/why this background download will be used. See documentation on that method for more information.
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use [check].
  ///
  /// Optionally specify [showNotification] as `false` to disable the built-in notification system.
  ///
  /// Optionally specify a [callback] that gets fired every time another tile is downloaded/failed, takes one [DownloadProgress] argument, and returns a boolean. Download can be cancelled by returning `true` from [callback] function.
  ///
  /// If the download doesn't seem to start on a device, try changing [useAltMethod] to `true`. This will switch to an older Android API, so should only be used if it is the most stable on a device. You may be able to programatically detect if the download hasn't started by using the callback, therefore allowing you to call this method again with [useAltMethod], but this isn't guranteed.
  ///
  /// _[preDownloadChecksCallback] has been deprecated without replacement or alternative. Usage will continue to function until the next minor release, at which time this functionality will be removed._
  ///
  /// Returns nothing.
  Future<void> startBackground({
    required DownloadableRegion region,
    FMTCTileProviderSettings? tileProviderSettings,
    bool disableRecovery = false,
    @Deprecated(
      '`preDownloadChecksCallback` has been deprecated without replacement or alternative. Usage will continue to function until the next minor release, at which time this functionality will be removed.',
    )
        PreDownloadChecksCallback preDownloadChecksCallback,
    bool Function(DownloadProgress)? callback,
    void Function()? preDownloadChecksFailedCallback,
    bool useAltMethod = false,
    bool showNotification = true,
    String notificationChannelName = 'Map Background Downloader',
    String notificationChannelDescription =
        'Displays progress notifications to inform the user about the progress of their map download.',
    String notificationIcon = '@mipmap/ic_launcher',
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
      final AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(notificationIcon);
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
            final download = startForeground(
              region: region,
              tileProviderSettings: tileProviderSettings,
              disableRecovery: disableRecovery,
              preDownloadChecksCallback: preDownloadChecksCallback,
            ).asBroadcastStream();
            if (await download.isEmpty) {
              await cancel();
              if (preDownloadChecksFailedCallback != null) {
                preDownloadChecksFailedCallback();
              }
              BackgroundFetch.finish(taskId);
              return;
            }

            sub = download.listen((event) async {
              final AndroidNotificationDetails androidPlatformChannelSpecifics =
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
                enableVibration: false,
                onlyAlertOnce: true,
                autoCancel: false,
              );
              final NotificationDetails platformChannelSpecifics =
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
                await sub!.cancel();
                await cancel();
                if (showNotification) {
                  await flutterLocalNotificationsPlugin!.cancel(0);
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
                await sub!.cancel();
                await cancel();
                if (showNotification) {
                  await flutterLocalNotificationsPlugin!.cancel(0);
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
          } else {
            BackgroundFetch.finish(taskId);
          }
        },
        (String taskId) async => BackgroundFetch.finish(taskId),
      );
      await BackgroundFetch.scheduleTask(
        TaskConfig(
          taskId: 'backgroundTileDownload',
          delay: 0,
          forceAlarmManager: useAltMethod,
        ),
      );
    } else {
      throw UnsupportedError(
        'The background download feature is only available on Android due to limitations with other operating systems.',
      );
    }
  }

  /// Check approximately how many downloadable tiles are within a specified [DownloadableRegion]
  ///
  /// This does not take into account sea tile removal or redownload prevention, as these are handled in the download area of the code.
  ///
  /// Returns an `int` which is the number of tiles.
  Future<int> check(DownloadableRegion region) async =>
      (await _generateTilesComputer(region)).length;

  /// Cancels the ongoing foreground download and recovery session (within the current object)
  ///
  /// Do not use to cancel background downloads, return `true` from the background download callback to cancel a background download. Background download cancellations require a few more 'shut-down' steps that can create unexpected issues and memory leaks if not carried out.
  Future<void> cancel() async {
    _queue?.dispose();
    await _streamController?.close();

    if (_recoveryId != null) {
      await _storeDirectory.rootDirectory.recovery.cancel(_recoveryId!);
    }
  }

  /// Requests for app to be excluded from battery optimizations to aid running a background process
  ///
  /// Only available on Android devices, due to limitations with other operating systems.
  ///
  /// Background downloading is complicated: see the documentation website for more information.
  ///
  /// If [requestIfDenied] is `true` (default), and the permission has not been granted, an intrusive system dialog will be displayed. If `false`, this method will only check whether it has been granted or not.
  ///
  /// If the dialog does appear it contains is no explanation for the user, except that the app will be allowed to run in the background all the time, so less technical users may be put off. It is up to you to decide (and program accordingly) if you want to show a reason first, then request the permission.
  ///
  /// Will return ([Future]) `true` if permission was granted, `false` if the permission was denied.
  Future<bool> requestIgnoreBatteryOptimizations(
    BuildContext context, {
    bool requestIfDenied = true,
  }) async {
    if (Platform.isAndroid) {
      final PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.status;

      if ((status.isDenied || status.isLimited) && requestIfDenied) {
        final PermissionStatus statusAfter =
            await Permission.ignoreBatteryOptimizations.request();
        if (statusAfter.isGranted) return true;
        return false;
      } else if (status.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      throw UnsupportedError(
        'The background download feature is only available on Android due to limitations with other operating systems.',
      );
    }
  }

  Stream<DownloadProgress> _startDownload({
    required FMTCTileProviderSettings? tileProviderSettings,
    required DownloadableRegion region,
    required List<Coords<num>> tiles,
  }) async* {
    final FMTCTileProvider tileProvider =
        _storeDirectory.getTileProvider(tileProviderSettings);
    final http.Client client = http.Client();

    Uint8List? seaTileBytes;
    if (region.seaTileRemoval) {
      try {
        seaTileBytes = (await client.get(
          Uri.parse(
            tileProvider.getTileUrl(Coords(0, 0)..z = 17, region.options),
          ),
        ))
            .bodyBytes;
      } catch (e) {
        seaTileBytes = null;
      }
    }

    int successfulTiles = 0;
    int seaTiles = 0;
    int existingTiles = 0;
    final List<String> failedTiles = [];
    final List<Duration> durationPerTile = [];
    final DateTime startTime = DateTime.now();

    final Stream<TileProgress> downloadStream = bulkDownloader(
      tiles: tiles,
      provider: tileProvider,
      options: region.options,
      client: client,
      parallelThreads: region.parallelThreads,
      errorHandler: region.errorHandler,
      preventRedownload: region.preventRedownload,
      seaTileBytes: seaTileBytes,
      queue: _queue!,
      streamController: _streamController!,
    );

    await for (final TileProgress evt in downloadStream) {
      if (evt.failedUrl == null) {
        successfulTiles++;
        unawaited(_storeDirectory.stats.invalidateCachedStatisticsAsync(null));
      } else {
        failedTiles.add(evt.failedUrl!);
      }

      seaTiles += evt.wasSeaTile ? 1 : 0;
      existingTiles += evt.wasExistingTile ? 1 : 0;

      durationPerTile.add(evt.duration);

      final DownloadProgress prog = DownloadProgress.internal(
        downloadID: _recoveryId!,
        maxTiles: tiles.length,
        successfulTiles: successfulTiles,
        failedTiles: failedTiles,
        seaTiles: seaTiles,
        existingTiles: existingTiles,
        durationPerTile: durationPerTile,
        duration: DateTime.now().difference(startTime),
        tileImage: evt.tileImage == null ? null : MemoryImage(evt.tileImage!),
      );

      yield prog;
      if (prog.percentageProgress >= 100) await cancel();
    }

    client.close();
  }

  static Future<List<Coords<num>>> _generateTilesComputer(
    DownloadableRegion region, {
    bool applyRange = true,
  }) async {
    final List<Coords<num>> tiles = await compute(
      region.type == RegionType.rectangle
          ? rectangleTiles
          : region.type == RegionType.circle
              ? circleTiles
              : lineTiles,
      {
        'bounds': LatLngBounds.fromPoints(region.points),
        'circleOutline': region.points,
        'lineOutline': region.points.chunked(4).toList(),
        'minZoom': region.minZoom,
        'maxZoom': region.maxZoom,
        'crs': region.crs,
        'tileSize':
            CustomPoint(region.options.tileSize, region.options.tileSize),
      },
    );

    if (!applyRange) return tiles;
    return tiles.getRange(region.start, region.end ?? tiles.length).toList();
  }
}

extension _ListExtensionsE<E> on List<E> {
  Iterable<List<E>> chunked(int size) sync* {
    for (var i = 0; i < length; i += size) {
      yield sublist(i, (i + size < length) ? i + size : length);
    }
  }
}
