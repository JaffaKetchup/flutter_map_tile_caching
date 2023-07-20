// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

Future<void> _downloadManager(
  ({
    SendPort sendPort,
    String rootDirectory,
    DownloadableRegion region,
    String storeName,
    int parallelThreads,
    int maxBufferLength,
    bool skipExistingTiles,
    bool skipSeaTiles,
    Duration? maxReportInterval,
    int? rateLimit,
    Iterable<RegExp> obscuredQueryParams,
  }) input,
) async {
  // Precalculate shared inputs for all threads
  final storeId = DatabaseTools.hash(input.storeName).toString();
  final threadBufferLength =
      (input.maxBufferLength / input.parallelThreads).ceil();
  final headers = {
    ...input.region.options.tileProvider.headers,
    'User-Agent': input.region.options.tileProvider.headers['User-Agent'] ==
            null
        ? 'flutter_map_tile_caching for flutter_map (unknown)'
        : 'flutter_map_tile_caching for ${input.region.options.tileProvider.headers['User-Agent']}',
  };

  // Count number of tiles
  final maxTiles = input.region.when(
    rectangle: TilesCounter.rectangleTiles,
    circle: TilesCounter.circleTiles,
    line: TilesCounter.lineTiles,
  );

  // Setup sea tile removal system
  Uint8List? seaTileBytes;
  if (input.skipSeaTiles) {
    try {
      seaTileBytes = await http.readBytes(
        Uri.parse(
          input.region.options.tileProvider.getTileUrl(
            const TileCoordinates(0, 0, 17),
            input.region.options,
          ),
        ),
        headers: headers,
      );
    } catch (_) {
      seaTileBytes = null;
    }
  }

  // Setup thread buffer tracking
  late final List<({double size, int tiles})> threadBuffers;
  if (input.maxBufferLength != 0) {
    threadBuffers = List.generate(
      input.parallelThreads,
      (_) => (tiles: 0, size: 0.0),
      growable: false,
    );
  }

  // Setup tile generator isolate
  final tileRecievePort = ReceivePort();
  final tileIsolate = await Isolate.spawn(
    input.region.when(
      rectangle: (_) => TilesGenerator.rectangleTiles,
      circle: (_) => TilesGenerator.circleTiles,
      line: (_) => TilesGenerator.lineTiles,
    ) as dynamic,
    (sendPort: tileRecievePort.sendPort, region: input.region),
    onExit: tileRecievePort.sendPort,
    debugName: '[FMTC] Tile Coords Generator Thread',
  );
  final rawTileStream = tileRecievePort.skip(input.region.start).take(
        input.region.end == null
            ? largestInt
            : (input.region.end! - input.region.start),
      );
  final tileQueue = StreamQueue(
    input.rateLimit == null
        ? rawTileStream
        : RateLimitedStream.fromSourceStream(
            emitEvery: Duration(
              microseconds: ((1 / input.rateLimit!) * 1000000).ceil(),
            ),
            sourceStream: rawTileStream,
          ).stream,
  );
  final requestTilePort = await tileQueue.next as SendPort;

  // Setup two-way communications with root
  final rootRecievePort = ReceivePort();
  void send(Object? m) => input.sendPort.send(m);
  send(rootRecievePort.sendPort);

  // Start progress tracking
  final downloadDuration = Stopwatch()..start();
  var lastDownloadProgress = DownloadProgress._initial(maxTiles: maxTiles);
  int mptTileIndex = -1;
  int mptSlots = 50;
  final microsecondsPerTile = List<int?>.filled(mptSlots, null, growable: true);
  final tpsRates = List<double?>.filled(20, null);
  final tileTimer = Stopwatch(); // This might be the wrong place to put this?

  // Setup cancel, pause, and resume handling
  final threadPausedStates = List.generate(
    input.parallelThreads,
    (_) => Completer(),
    growable: false,
  );
  final cancelSignal = Completer<void>();
  Completer<void> pauseResumeSignal = Completer()..complete();
  rootRecievePort.listen(
    (e) async {
      if (e == null) {
        try {
          cancelSignal.complete();
          // ignore: avoid_catching_errors, empty_catches
        } on StateError {}
      } else if (e == 1) {
        pauseResumeSignal = Completer();
        for (int i = 0; i < input.parallelThreads; i++) {
          threadPausedStates[i] = Completer();
        }
        await Future.wait(threadPausedStates.map((e) => e.future));
        downloadDuration.stop();
        send(1);
      } else if (e == 2) {
        pauseResumeSignal.complete();
        downloadDuration.start();
      }
    },
  );

  // Setup progress report fallback
  final Timer? fallbackReportTimer;
  if (input.maxReportInterval case final maxReportInterval?) {
    fallbackReportTimer = Timer.periodic(
      maxReportInterval,
      (_) {
        if (lastDownloadProgress !=
                DownloadProgress._initial(maxTiles: maxTiles) &&
            pauseResumeSignal.isCompleted) {
          final tps = tpsRates.nonNulls.average;
          send(
            lastDownloadProgress = lastDownloadProgress._updateProgress(
              newDuration: downloadDuration.elapsed,
              tilesPerSecond: tps,
              rateLimit: input.rateLimit,
            ),
          );
        }
      },
    );
  } else {
    fallbackReportTimer = null;
  }

  // Start download threads & wait for download to complete/cancelled
  await Future.wait(
    List.generate(
      input.parallelThreads,
      (threadNo) async {
        if (cancelSignal.isCompleted) return;

        // Start thread worker isolate & setup two-way communications
        final downloadThreadRecievePort = ReceivePort();
        await Isolate.spawn(
          _singleDownloadThread,
          (
            sendPort: downloadThreadRecievePort.sendPort,
            storeId: storeId,
            rootDirectory: input.rootDirectory,
            options: input.region.options,
            maxBufferLength: threadBufferLength,
            skipExistingTiles: input.skipExistingTiles,
            seaTileBytes: seaTileBytes,
            obscuredQueryParams: input.obscuredQueryParams,
            headers: headers,
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
              // Handle progress estimation measurements
              mptTileIndex++;
              microsecondsPerTile[mptTileIndex % mptSlots] =
                  (tileTimer..stop()).elapsedMicroseconds;
              final rawTPS =
                  (1 / (microsecondsPerTile.nonNulls.average)) * 1000000;
              microsecondsPerTile.length = mptSlots = rawTPS.ceil() * 2;
              tpsRates[mptTileIndex % 20] = rawTPS;
              final tps = tpsRates.nonNulls.average;

              // If buffering is in use, send a progress update with buffer info
              if (input.maxBufferLength != 0) {
                if (evt.result == TileEventResult.success) {
                  threadBuffers[threadNo] = (
                    tiles: evt._wasBufferReset
                        ? 0
                        : threadBuffers[threadNo].tiles + 1,
                    size: evt._wasBufferReset
                        ? 0
                        : threadBuffers[threadNo].size +
                            (evt.tileImage!.lengthInBytes / 1024)
                  );
                }

                send(
                  lastDownloadProgress =
                      lastDownloadProgress._updateProgressWithTile(
                    newTileEvent: evt,
                    newBufferedTiles: threadBuffers
                        .map((e) => e.tiles)
                        .reduce((a, b) => a + b),
                    newBufferedSize: threadBuffers
                        .map((e) => e.size)
                        .reduce((a, b) => a + b),
                    newDuration: downloadDuration.elapsed,
                    tilesPerSecond: tps,
                    rateLimit: input.rateLimit,
                  ),
                );
              } else {
                send(
                  lastDownloadProgress =
                      lastDownloadProgress._updateProgressWithTile(
                    newTileEvent: evt,
                    newBufferedTiles: 0,
                    newBufferedSize: 0,
                    newDuration: downloadDuration.elapsed,
                    tilesPerSecond: tps,
                    rateLimit: input.rateLimit,
                  ),
                );
              }
              return;
            }

            // Thread is requesting new tile coords
            if (evt is int) {
              if (!pauseResumeSignal.isCompleted) {
                threadPausedStates[threadNo].complete();
                await pauseResumeSignal.future;
              }

              tileTimer
                ..reset()
                ..start();

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
    ),
  );

  // Send final buffer cleared progress report
  fallbackReportTimer?.cancel();
  send(
    lastDownloadProgress = lastDownloadProgress._updateProgressWithTile(
      newTileEvent: null,
      newBufferedTiles: 0,
      newBufferedSize: 0,
      newDuration: downloadDuration.elapsed,
      tilesPerSecond: 0,
      rateLimit: input.rateLimit,
      isComplete: true,
    ),
  );

  // Cleanup resources and shutdown
  downloadDuration.stop();
  rootRecievePort.close();
  tileIsolate.kill(priority: Isolate.immediate);
  await tileQueue.cancel(immediate: true);
  Isolate.exit();
}
