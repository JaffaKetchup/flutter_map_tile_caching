// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

Future<void> _downloadManager(
  ({
    SendPort sendPort,
    DownloadableRegion region,
    String storeName,
    int parallelThreads,
    int maxBufferLength,
    bool skipExistingTiles,
    bool skipSeaTiles,
    Duration? maxReportInterval,
    int? rateLimit,
    List<RegExp> obscuredQueryParams,
    int? recoveryId,
    FMTCBackendInternalThreadSafe backend,
  }) input,
) async {
  // Precalculate how large the tile buffers should be for each thread
  final threadBufferLength =
      (input.maxBufferLength / input.parallelThreads).floor();

  // Generate appropriate headers for network requests
  final inputHeaders = input.region.options.tileProvider.headers;
  final headers = {
    ...inputHeaders,
    'User-Agent': inputHeaders['User-Agent'] == null
        ? 'flutter_map (unknown)'
        : 'flutter_map + FMTC ${inputHeaders['User-Agent']!.replaceRange(
            0,
            inputHeaders['User-Agent']!.length.clamp(0, 12),
            '',
          )}',
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
  late final List<int> threadBuffersSize;
  late final List<int> threadBuffersTiles;
  if (input.maxBufferLength != 0) {
    // TODO: Verify `filled`
    threadBuffersSize = List.filled(input.parallelThreads, 0);
    threadBuffersTiles = List.filled(input.parallelThreads, 0);
  }

  // Setup tile generator isolate
  final tileReceivePort = ReceivePort();
  final tileIsolate = await Isolate.spawn(
    input.region.when(
      rectangle: (_) => TileGenerators.rectangleTiles,
      circle: (_) => TileGenerators.circleTiles,
      line: (_) => TileGenerators.lineTiles,
      customPolygon: (_) => TileGenerators.customPolygonTiles,
    ),
    (sendPort: tileReceivePort.sendPort, region: input.region),
    onExit: tileReceivePort.sendPort,
    debugName: '[FMTC] Tile Coords Generator Thread',
  );
  final tileQueue = StreamQueue(
    input.rateLimit == null
        ? tileReceivePort
        : tileReceivePort.rateLimit(
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
  Iterable<Completer<void>> generateThreadPausedStates() => Iterable.generate(
        input.parallelThreads,
        (_) => Completer<void>(),
      );
  final threadPausedStates = generateThreadPausedStates().toList();
  final cancelSignal = Completer<void>();
  var pauseResumeSignal = Completer<void>()..complete();
  rootReceivePort.listen(
    (cmd) async {
      switch (cmd) {
        case _DownloadManagerControlCmd.cancel:
          try {
            cancelSignal.complete();
            // ignore: avoid_catching_errors, empty_catches
          } on StateError {}
        case _DownloadManagerControlCmd.pause:
          pauseResumeSignal = Completer<void>();
          threadPausedStates.setAll(0, generateThreadPausedStates());
          await Future.wait(threadPausedStates.map((e) => e.future));
          downloadDuration.stop();
          send(_DownloadManagerControlCmd.pause);
        case _DownloadManagerControlCmd.resume:
          pauseResumeSignal.complete();
          downloadDuration.start();
        default:
          throw UnimplementedError('Recieved unknown control cmd: $cmd');
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

  // Start recovery system (unless disabled)
  if (input.recoveryId case final recoveryId?) {
    await input.backend.initialise();
    await input.backend.startRecovery(
      id: recoveryId,
      storeName: input.storeName,
      region: input.region,
      endTile: math.min(input.region.end ?? largestInt, maxTiles),
    );
    // TODO: Remove once validated
    // send(2);
  }

  // Create convienience method to update recovery system if enabled
  void updateRecoveryIfNecessary() {
    if (input.recoveryId case final recoveryId?) {
      input.backend.updateRecovery(
        id: recoveryId,
        newStartTile: 1 +
            (lastDownloadProgress.cachedTiles -
                lastDownloadProgress.bufferedTiles),
      );
    }
  }

  // Duplicate the backend to make it safe to send through isolates
  final threadBackend = input.backend.duplicate();

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
            options: input.region.options,
            maxBufferLength: threadBufferLength,
            skipExistingTiles: input.skipExistingTiles,
            seaTileBytes: seaTileBytes,
            obscuredQueryParams: input.obscuredQueryParams,
            headers: headers,
            backend: threadBackend,
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
                // Update correct thread buffer with new tile on success
                if (evt.result == TileEventResult.success) {
                  if (evt._wasBufferReset) {
                    threadBuffersSize[threadNo] = 0;
                    threadBuffersTiles[threadNo] = 0;
                  } else {
                    threadBuffersSize[threadNo] += evt.tileImage!.lengthInBytes;
                    threadBuffersTiles[threadNo]++;
                  }
                }

                send(
                  lastDownloadProgress =
                      lastDownloadProgress._updateProgressWithTile(
                    newTileEvent: evt,
                    newBufferedTiles:
                        threadBuffersTiles.reduce((a, b) => a + b),
                    newBufferedSize:
                        threadBuffersSize.reduce((a, b) => a + b) / 1024,
                    newDuration: downloadDuration.elapsed,
                    tilesPerSecond: getCurrentTPS(registerNewTPS: true),
                    rateLimit: input.rateLimit,
                  ),
                );

                // For efficiency, only update recovery when the buffer is
                // cleaned
                // We don't want to update recovery to a tile that isn't cached
                // (only buffered), because they'll be lost in the events
                // recovery is designed to recover from
                if (evt._wasBufferReset) updateRecoveryIfNecessary();
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

                updateRecoveryIfNecessary();
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
  if (input.recoveryId != null) await input.backend.uninitialise();
  tileIsolate.kill(priority: Isolate.immediate);
  await tileQueue.cancel(immediate: true);
  Isolate.exit();
}
