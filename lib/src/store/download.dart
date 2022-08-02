// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_info/enums/charging_status.dart';
import 'package:battery_info/model/android_battery_info.dart';
import 'package:battery_info/model/iso_battery_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:queue/queue.dart';

import '../bulk_download/download_progress.dart';
import '../bulk_download/downloader.dart';
import '../bulk_download/internal_timing_progress_management.dart';
import '../bulk_download/tile_loops.dart';
import '../bulk_download/tile_progress.dart';
import '../internal/exts.dart';
import '../internal/tile_provider.dart';
import '../misc/typedefs.dart';
import '../regions/downloadable_region.dart';
import '../settings/tile_provider_settings.dart';
import 'directory.dart';

/// Provides tools to manage bulk downloading to a specific [StoreDirectory]
///
/// Is a singleton to ensure functioning as expected.
class DownloadManagement {
  /// The store directory to provide access paths to
  final StoreDirectory _storeDirectory;

  /// Used internally to queue download tiles to process in bulk
  Queue? _queue;

  /// Used internally to keep track of the recovery file
  int? _recoveryId;

  /// Used internally to control bulk downloading
  StreamController<TileProgress>? _streamController;

  /// Used internally to manage tiles per second progress calculations
  late InternalProgressTimingManagement _progressManagement;

  /// Provides tools to manage bulk downloading to a specific [StoreDirectory]
  ///
  /// Is a singleton to ensure functioning as expected.
  factory DownloadManagement(StoreDirectory storeDirectory) {
    if (!_instances.keys.contains(storeDirectory)) {
      _instances[storeDirectory] = DownloadManagement._(storeDirectory);
    }
    return _instances[storeDirectory]!;
  }

  /// Provides tools to manage bulk downloading to a specific [StoreDirectory]
  ///
  /// Is a singleton to ensure functioning as expected.
  DownloadManagement._(this._storeDirectory);

  /// Contains the intialised instances of [DownloadManagement]s
  static final Map<StoreDirectory, DownloadManagement> _instances = {};

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
        storeName: _storeDirectory.storeName,
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

  /// Download a specified [DownloadableRegion] in the background, and show a progress notification (by default)
  ///
  /// To check the number of tiles that need to be downloaded before using this function, use [check].
  ///
  /// Only available on Android devices, due to limitations with other operating systems. Background downloading is complicated: see the documentation website for more information.
  ///
  /// Calling this method will automatically request the necessary permissions. You may want to call [requestIgnoreBatteryOptimizations] beforehand, as this will allow you more control.
  ///
  /// Uses a foreground service internally, meaning the process should be stable unless the application is force stopped/fully closed. However, you should still read the Limitations page, available in the online documentation.
  ///
  /// Displays two notifications:
  /// * A service notification, informing the user that the process is running. This is unavoidable due to the system limitations, however it can be easily hidden by the user. The default text explains this process roughly.
  /// * A progress notification, informing the user of the current state of the download. Includes a progress bar and time estimate by default.
  ///
  /// Configure the progress notification using:
  /// * `showProgressNotification`: set to `false` to disable the progress notification - not recommended
  /// * `progressNotificationIcon`: set to a string in the format '@\<type\>/\<name\>' (found in the 'android\app\src\main\res') to override the default icon ('@mipmap/ic_notification_icon': only available in the example application)
  /// * `progressNotificationTitle`: set to a `String` to override the default title
  /// * `progressNotificationText`: set to a `String` to override the default body text
  /// * `progressNotificationConfig`: use to further customise the notification properties
  ///
  /// Configure the background notification using:
  /// * `backgroundNotificationIcon`: set to an `AndroidResource` to override the default icon ('@mipmap/ic_launcher': the app's launcher icon)
  /// * `backgroundNotificationTitle`: set to a `String` to override the default title
  /// * `backgroundNotificationText`: set to a `String` to override the default body text
  Future<void> startBackground({
    required DownloadableRegion region,
    FMTCTileProviderSettings? tileProviderSettings,
    bool disableRecovery = false,
    String backgroundNotificationTitle = 'App Running In Background',
    String backgroundNotificationText =
        "Hide this notification by holding down and opening the notification's settings. Then disable this notification only.",
    AndroidResource? backgroundNotificationIcon,
    bool showProgressNotification = true,
    AndroidNotificationDetails? progressNotificationConfig,
    String progressNotificationIcon = '@mipmap/ic_notification_icon',
    String progressNotificationTitle = 'Downloading Map...',
    String Function(DownloadProgress)? progressNotificationBody,
    @Deprecated(
      '`preDownloadChecksCallback` has been deprecated without replacement or alternative. Usage will no longer have any effect. This functionality will be removed in the next minor release',
    )
        PreDownloadChecksCallback preDownloadChecksCallback,
  }) async {
    if (Platform.isAndroid) {
      final bool initSuccess = await FlutterBackground.initialize(
        androidConfig: FlutterBackgroundAndroidConfig(
          notificationTitle: backgroundNotificationTitle,
          notificationText: backgroundNotificationText,
          notificationIcon: backgroundNotificationIcon ??
              const AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        ),
      );
      if (!initSuccess) {
        throw StateError(
          'Failed to acquire the necessary permissions to run the background process',
        );
      }

      final bool startSuccess =
          await FlutterBackground.enableBackgroundExecution();
      if (!startSuccess) {
        throw StateError('Failed to start the background process');
      }

      final notification = FlutterLocalNotificationsPlugin();
      await notification.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings(progressNotificationIcon),
        ),
      );

      final Stream<DownloadProgress> downloadStream = startForeground(
        region: region,
        tileProviderSettings: tileProviderSettings,
        disableRecovery: disableRecovery,
        preDownloadChecksCallback: preDownloadChecksCallback,
      ).asBroadcastStream();
      if (await downloadStream.isEmpty) return cancel();

      final AndroidNotificationDetails androidNotificationDetails =
          progressNotificationConfig?.copyWith(
                channelId: 'FMTCMapDownloader',
                ongoing: true,
              ) ??
              const AndroidNotificationDetails(
                'FMTCMapDownloader',
                'Map Download Progress',
                channelDescription:
                    'Displays progress notifications to inform the user about the progress of their map download',
                showProgress: true,
                visibility: NotificationVisibility.public,
                subText: 'Map Downloader',
                importance: Importance.low,
                priority: Priority.low,
                showWhen: false,
                playSound: false,
                enableVibration: false,
                onlyAlertOnce: true,
                autoCancel: false,
                ongoing: true,
              );

      late final StreamSubscription<DownloadProgress> subscription;

      subscription = downloadStream.listen(
        (event) async {
          if (showProgressNotification) {
            await notification.show(
              0,
              progressNotificationTitle,
              progressNotificationBody == null
                  ? '${event.attemptedTiles}/${event.maxTiles} (${event.percentageProgress.round().toString()}%)'
                  : progressNotificationBody(event),
              NotificationDetails(
                android: androidNotificationDetails.copyWith(
                  maxProgress: event.maxTiles,
                  progress: event.attemptedTiles,
                ),
              ),
            );
          }
        },
        onDone: () async {
          if (showProgressNotification) await notification.cancel(0);
          await subscription.cancel();
          await cancel();
        },
      );
    } else {
      throw PlatformException(
        code: 'notAndroid',
        message:
            'The background download feature is only available on Android due to internal limitations.',
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
    unawaited(_streamController?.close());
    unawaited(_progressManagement.stopTracking());

    if (_recoveryId != null) {
      await _storeDirectory.rootDirectory.recovery.cancel(_recoveryId!);
    }

    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }

  /// Requests for app to be excluded from battery optimizations to aid running a background process
  ///
  /// Only available on Android devices, due to limitations with other operating systems.
  ///
  /// Background downloading is complicated: see the documentation website for more information.
  ///
  /// If [requestIfDenied] is `true` (default), and the permission has not been granted, an intrusive system dialog/screen will be displayed. If `false`, this method will only check whether it has been granted or not.
  ///
  /// Will return `true` if permission was granted, `false` if the permission was denied.
  Future<bool> requestIgnoreBatteryOptimizations({
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
      throw PlatformException(
        code: 'notAndroid',
        message:
            'The background download feature is only available on Android due to internal limitations.',
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
    int successfulSize = 0;
    int seaTiles = 0;
    int existingTiles = 0;
    final List<String> failedTiles = [];
    final DateTime startTime = DateTime.now();

    _progressManagement = InternalProgressTimingManagement()..startTracking();

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
      downloadID: _recoveryId!,
      progressManagement: _progressManagement,
    );

    await for (final TileProgress evt in downloadStream) {
      if (evt.failedUrl == null) {
        successfulTiles++;
        unawaited(_storeDirectory.stats.invalidateCachedStatisticsAsync());
      } else {
        failedTiles.add(evt.failedUrl!);
      }

      successfulSize += evt.sizeBytes;

      seaTiles += evt.wasSeaTile ? 1 : 0;
      existingTiles += evt.wasExistingTile ? 1 : 0;

      final DownloadProgress prog = DownloadProgress.internal(
        downloadID: _recoveryId!,
        maxTiles: tiles.length,
        successfulTiles: successfulTiles,
        failedTiles: failedTiles,
        successfulSize: successfulSize / 1024,
        seaTiles: seaTiles,
        existingTiles: existingTiles,
        duration: DateTime.now().difference(startTime),
        tileImage: evt.tileImage == null ? null : MemoryImage(evt.tileImage!),
        progressManagement: _progressManagement,
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
