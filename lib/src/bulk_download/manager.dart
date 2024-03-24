// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

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
    FMTCBackendInternalThreadSafe backend,
  }) input,
) async {
  // Precalculate shared inputs for all threads
  final threadBufferLength =
      (input.maxBufferLength / input.parallelThreads).floor();
  final headers = {
    ...input.region.options.tileProvider.headers,
    'User-Agent': input.region.options.tileProvider.headers['User-Agent'] ==
            null
        ? 'flutter_map_tile_caching for flutter_map (unknown)'
        : 'flutter_map_tile_caching for ${input.region.options.tileProvider.headers['User-Agent']}',
  };

  // Count number of tiles
  final maxTiles = input.region.when(
    rectangle: TileCounters.rectangleTiles,
    circle: TileCounters.circleTiles,
    line: TileCounters.lineTiles,
    customPolygon: TileCounters.customPolygonTiles,
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
  final tilereceivePort = ReceivePort();
  final tileIsolate = await Isolate.spawn(
    input.region.when(
      rectangle: (_) => TileGenerators.rectangleTiles,
      circle: (_) => TileGenerators.circleTiles,
      line: (_) => TileGenerators.lineTiles,
      customPolygon: (_) => TileGenerators.customPolygonTiles,
    ),
    (sendPort: tilereceivePort.sendPort, region: input.region),
    onExit: tilereceivePort.sendPort,
    debugName: '[FMTC] Tile Coords Generator Thread',
  );
  final rawTileStream = tilereceivePort.skip(input.region.start).take(
        input.region.end == null
            ? largestInt
            : (input.region.end! - input.region.start),
      );
  final tileQueue = StreamQueue(
    input.rateLimit == null
        ? rawTileStream
        : rawTileStream.rateLimit(
            minimumSpacing: Duration(
              microseconds: ((1 / input.rateLimit!) * 1000000).ceil(),
            ),
          ),
  );
  final requestTilePort = await tileQueue.next as SendPort;

  // Start progress tracking
  final initialDownloadProgress = DownloadProgress._initial(maxTiles: maxTiles);
  var lastDownloadProgress = initialDownloadProgress;
  final downloadDuration = Stopwatch();
  final tileCompletionTimestamps = <DateTime>[];
  const tpsSmoothingFactor = 0.5;
  final tpsSmoothingStorage = <int?>[null];
  int currentTPSSmoothingIndex = 0;
  double getCurrentTPS({required bool registerNewTPS}) {
    if (registerNewTPS) tileCompletionTimestamps.add(DateTime.timestamp());
    tileCompletionTimestamps.removeWhere(
      (e) =>
          e.isBefore(DateTime.timestamp().subtract(const Duration(seconds: 1))),
    );
    currentTPSSmoothingIndex++;
    tpsSmoothingStorage[currentTPSSmoothingIndex % tpsSmoothingStorage.length] =
        tileCompletionTimestamps.length;
    final tps = tpsSmoothingStorage.nonNulls.average;
    tpsSmoothingStorage.length =
        (tps * tpsSmoothingFactor).ceil().clamp(1, 1000);
    return tps;
  }

  // Setup two-way communications with root
  final rootReceivePort = ReceivePort();
  void send(Object? m) => input.sendPort.send(m);

  // Setup cancel, pause, and resume handling
  List<Completer<void>> generateThreadPausedStates() => List.generate(
        input.parallelThreads,
        (_) => Completer<void>(),
        growable: false,
      );
  final threadPausedStates = generateThreadPausedStates();
  final cancelSignal = Completer<void>();
  var pauseResumeSignal = Completer<void>()..complete();
  rootReceivePort.listen(
    (e) async {
      if (e == null) {
        try {
          cancelSignal.complete();
          // ignore: avoid_catching_errors, empty_catches
        } on StateError {}
      } else if (e == 1) {
        pauseResumeSignal = Completer<void>();
        threadPausedStates.setAll(0, generateThreadPausedStates());
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
  final fallbackReportTimer = input.maxReportInterval == null
      ? null
      : Timer.periodic(
          input.maxReportInterval!,
          (_) {
            if (lastDownloadProgress != initialDownloadProgress &&
                pauseResumeSignal.isCompleted) {
              send(
                lastDownloadProgress =
                    lastDownloadProgress._fallbackReportUpdate(
                  newDuration: downloadDuration.elapsed,
                  tilesPerSecond: getCurrentTPS(registerNewTPS: false),
                  rateLimit: input.rateLimit,
                ),
              );
            }
          },
        );

  // Now it's safe, start accepting communications from the root
  send(rootReceivePort.sendPort);

  // Start download threads & wait for download to complete/cancelled
  downloadDuration.start();
  await Future.wait(
    List.generate(
      input.parallelThreads,
      (threadNo) async {
        if (cancelSignal.isCompleted) return;

        // Start thread worker isolate & setup two-way communications
        final downloadThreadReceivePort = ReceivePort();
        await Isolate.spawn(
          _singleDownloadThread,
          (
            sendPort: downloadThreadReceivePort.sendPort,
            storeName: input.storeName,
            rootDirectory: input.rootDirectory,
            options: input.region.options,
            maxBufferLength: threadBufferLength,
            skipExistingTiles: input.skipExistingTiles,
            seaTileBytes: seaTileBytes,
            obscuredQueryParams: input.obscuredQueryParams,
            headers: headers,
            backend: input.backend,
          ),
          onExit: downloadThreadReceivePort.sendPort,
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
              .then((_) => sendPortCompleter.future)
              .then((sp) => sp.send(null)),
        );

        downloadThreadReceivePort.listen(
          (evt) async {
            // Thread is sending tile data
            if (evt is TileEvent) {
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
                    tilesPerSecond: getCurrentTPS(registerNewTPS: true),
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
                    tilesPerSecond: getCurrentTPS(registerNewTPS: true),
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
            if (evt == null) return downloadThreadReceivePort.close();
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
  downloadDuration.stop();

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
  rootReceivePort.close();
  tileIsolate.kill(priority: Isolate.immediate);
  await tileQueue.cancel(immediate: true);
  Isolate.exit();
}
