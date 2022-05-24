import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_info/enums/charging_status.dart';
import 'package:battery_info/model/android_battery_info.dart';
import 'package:battery_info/model/iso_battery_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'package:queue/queue.dart';

import '../../bulk_download/download_progress.dart';
import '../../bulk_download/downloader.dart';
import '../../bulk_download/tile_loops.dart';
import '../../bulk_download/tile_progress.dart';
import '../../misc/typedefs.dart';
import '../../regions/downloadable_region.dart';
import '../recovery/recovery.dart';
import '../tile_provider.dart';
import 'directory.dart';

/// Provides tools to manage bulk downloading to a specific [StoreDirectory]
class DownloadManagement {
  /// The store directory to provide access paths to
  final StoreDirectory _storeDirectory;

  /// Used internally to queue download tiles to process in bulk
  Queue? _queue;

  /// Used internally to store the state of recovery
  Recovery? _recovery;

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
  /// For more information on [preDownloadChecksCallback], see documentation on [PreDownloadChecksCallback]. In a few words, use this callback to check the devices information/status before starting a download. By default, no checks are made (null), but this is not recommended.
  ///
  /// Streams a [DownloadProgress] object containing lots of handy information about the download's progression status; unless the pre-download checks fail, in which case the stream's `.isEmpty` will be `true` and no new events will be emitted. If you get messages about 'Bad State' after dealing with the checks, just add `.asBroadcastStream()` on the end of [start].
  Stream<DownloadProgress> start({
    required DownloadableRegion region,
    FMTCTileProviderSettings? tileProviderSettings,
    bool disableRecovery = false,
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

    if (!disableRecovery) {
      _recovery = Recovery(_storeDirectory);
      await _recovery!.startRecovery(
        region,
        '${_storeDirectory.storeName}: ${region.type.name[0].toUpperCase() + region.type.name.substring(1)} Type',
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
    await _recovery?.endRecovery();
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
            tileProvider.getTileUrl(Coords(0, 0)..z = 19, region.options),
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
      } else {
        failedTiles.add(evt.failedUrl!);
      }

      seaTiles += evt.wasSeaTile ? 1 : 0;
      existingTiles += evt.wasExistingTile ? 1 : 0;

      durationPerTile.add(evt.duration);

      final DownloadProgress prog = DownloadProgress.internal(
        maxTiles: tiles.length,
        successfulTiles: successfulTiles,
        failedTiles: failedTiles,
        seaTiles: seaTiles,
        existingTiles: existingTiles,
        durationPerTile: durationPerTile,
        duration: DateTime.now().difference(startTime),
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
