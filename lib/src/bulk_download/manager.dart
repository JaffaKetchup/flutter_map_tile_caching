// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';
import '../db/tools.dart';
import '../misc/int_extremes.dart';
import 'thread.dart';
import 'tile_loops/shared.dart';

@internal
Future<void> downloadManager(
  ({
    SendPort sendPort,
    String rootDirectory,
    DownloadableRegion region,
    FMTCTileProvider tileProvider,
    int parallelThreads,
    int maxBufferLength,
    bool pruneExistingTiles,
    bool pruneSeaTiles,
    Duration? maxReportInterval,
  }) input,
) async {
  // Count number of tiles
  final maxTiles = input.region.when(
    rectangle: (_) => TilesCounter.rectangleTiles,
    circle: (_) => TilesCounter.circleTiles,
    line: (_) => TilesCounter.lineTiles,
  )(input.region);

  // Setup sea tile removal system
  Uint8List? seaTileBytes;
  if (input.pruneSeaTiles) {
    try {
      seaTileBytes = await http.readBytes(
        Uri.parse(
          input.tileProvider.getTileUrl(
            const TileCoordinates(0, 0, 17),
            input.region.options,
          ),
        ),
        headers: input.tileProvider.headers,
      );
    } catch (_) {
      seaTileBytes = null;
    }
  }

  // Setup tile generator isolate
  final tileRecievePort = ReceivePort();
  final tileIsolate = await Isolate.spawn(
    input.region.when(
      rectangle: (_) => TilesGenerator.rectangleTiles,
      circle: (_) => TilesGenerator.circleTiles,
      line: (_) => TilesGenerator.lineTiles,
    ),
    (sendPort: tileRecievePort.sendPort, region: input.region),
    onExit: tileRecievePort.sendPort,
    debugName: '[FMTC] Tile Coords Generator Thread',
  );
  final tileQueue = StreamQueue(
    tileRecievePort.skip(input.region.start).take(
          input.region.end == null
              ? largestInt
              : (input.region.end! - input.region.start),
        ),
  );
  final requestTilePort = await tileQueue.next as SendPort;

  // Setup two-way communications with root
  final rootRecievePort = ReceivePort();
  void send(Object? m) => input.sendPort.send(m);
  send(rootRecievePort.sendPort);

  // Setup cancel signal handling
  final cancelSignal = Completer<void>();
  unawaited(
    rootRecievePort.firstWhere((e) => e == null).then((_) {
      try {
        cancelSignal.complete();
        // ignore: avoid_catching_errors, empty_catches
      } on StateError {}
    }),
  );

  // Start progress tracking
  final downloadDuration = Stopwatch()..start();
  var lastDownloadProgress = DownloadProgress.initial(maxTiles: maxTiles);

  // Setup progress report fallback
  final Timer? fallbackReportTimer;
  if (input.maxReportInterval case final maxReportInterval?) {
    fallbackReportTimer = Timer.periodic(
      maxReportInterval,
      (_) => send(
        lastDownloadProgress =
            lastDownloadProgress.update(newDuration: downloadDuration.elapsed),
      ),
    );
  } else {
    fallbackReportTimer = null;
  }

  // Start download threads
  final downloadThreads = List.generate(
    input.parallelThreads,
    (threadNo) async {
      if (cancelSignal.isCompleted) return;

      // Start thread worker isolate & setup two-way communications
      final downloadThreadRecievePort = ReceivePort();
      await Isolate.spawn(
        singleDownloadThread,
        (
          sendPort: downloadThreadRecievePort.sendPort,
          storeId:
              DatabaseTools.hash(input.tileProvider.storeDirectory.storeName)
                  .toString(),
          rootDirectory: input.rootDirectory,
          region: input.region,
          tileProvider: input.tileProvider,
          maxBufferLength:
              (input.maxBufferLength / input.parallelThreads).ceil(),
          pruneExistingTiles: input.pruneExistingTiles,
          seaTileBytes: seaTileBytes,
        ),
        onExit: downloadThreadRecievePort.sendPort,
        debugName: '[FMTC] Bulk Download Thread #$threadNo',
      );
      late final SendPort sendPort;
      final sendPortCompleter = Completer<SendPort>();

      // Prevent completion of this function until the thread is shutdown
      final threadKilled = Completer<void>();

      // When one thread is complete, or the manual cancel signal is sent,
      // kill all threads
      unawaited(
        cancelSignal.future
            .then((_) async => (await sendPortCompleter.future).send(null)),
      );

      downloadThreadRecievePort.listen(
        (evt) async {
          // Thread is sending tile data
          if (evt is TileEvent) {
            send(
              lastDownloadProgress = lastDownloadProgress.update(
                newTileEvent: evt,
                newDuration: downloadDuration.elapsed,
              ),
            );
            return;
          }

          // Thread is requesting new tile coords
          if (evt is int) {
            requestTilePort.send(null);
            try {
              sendPort.send(await tileQueue.next);
              // ignore: avoid_catching_errors
            } on StateError {
              sendPort.send(null);
            }
            return;
          }

          // Thread is establishing comms
          if (evt is SendPort) {
            sendPortCompleter.complete(evt);
            sendPort = evt;
            return;
          }

          // Thread ended, goto `onDone`
          if (evt == null) return downloadThreadRecievePort.close();
        },
        onDone: () {
          try {
            cancelSignal.complete();
            // ignore: avoid_catching_errors, empty_catches
          } on StateError {}

          threadKilled.complete();
        },
      );

      // Prevent completion of this function until the thread is shutdown
      await threadKilled.future;
    },
    growable: false,
  );

  // Wait for download to complete/be fully cancelled
  await Future.wait(downloadThreads);

  // Cleanup resources and shutdown
  fallbackReportTimer?.cancel();
  downloadDuration.stop();
  await tileQueue.cancel(immediate: true);
  tileIsolate.kill(priority: Isolate.immediate);
  rootRecievePort.close();
  Isolate.exit();
}
