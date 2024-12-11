// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

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
    bool retryFailedRequestTiles,
    String Function(String) urlTransformer,
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
    multi: TileCounters.multiTiles,
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
    threadBuffersSize = List.filled(input.parallelThreads, 0);
    threadBuffersTiles = List.filled(input.parallelThreads, 0);
  }

  // Setup tile generation
  final tileReceivePort = ReceivePort();
  final tileIsolate = await Isolate.spawn(
    (({SendPort sendPort, DownloadableRegion region}) input) =>
        input.region.when(
      rectangle: (region) => TileGenerators.rectangleTiles(
        (sendPort: input.sendPort, region: region),
      ),
      circle: (region) => TileGenerators.circleTiles(
        (sendPort: input.sendPort, region: region),
      ),
      line: (region) => TileGenerators.lineTiles(
        (sendPort: input.sendPort, region: region),
      ),
      customPolygon: (region) => TileGenerators.customPolygonTiles(
        (sendPort: input.sendPort, region: region),
      ),
      multi: (region) => TileGenerators.multiTiles(
        (sendPort: input.sendPort, region: region),
      ),
    ),
    (sendPort: tileReceivePort.sendPort, region: input.region),
    onExit: tileReceivePort.sendPort,
    debugName: '[FMTC] Tile Coords Generator Thread',
  );

  // Setup retry tile utils
  final retryTiles = <(int, int, int)>[];
  bool isRetryingTiles = false;
  (int, int, int)? lastTileRetry; // See explanation below

  // Merge generated and retry tile streams together
  final mergedTileStreams = () async* {
    // First, output the generated tile stream
    // This stream only emits events when a tile is requested, to minimize
    // memory consumption
    await for (final evt in tileReceivePort) {
      if (evt == null) break;
      yield evt;
    }

    // After there are no more new tiles available, emit retry tiles if
    // necessary
    // We must store these coordinates in memory, so there is no use
    // implementing a request/recieve system as above
    // We send the retry tiles through this path to ensure they are rate limited
    if (retryTiles.isEmpty) return;
    assert(
      input.retryFailedRequestTiles,
      'Should not record tiles for retry when disabled',
    );
    // We set a flag, so threads are aware, so `TileEvent`s are aware, so stats
    // are aware
    isRetryingTiles = true;
    yield* Stream.fromIterable(retryTiles); // Must not modify during streaming
    // We cannot add events to the list of tiles during its streaming, so we
    // make a special place to store the the potential failure of the last
    // fresh tile
    if (lastTileRetry != null) yield lastTileRetry;
  }();
  final tileQueue = StreamQueue(
    input.rateLimit == null
        ? mergedTileStreams
        : mergedTileStreams.rateLimit(
            minimumSpacing: Duration(
              microseconds: ((1 / input.rateLimit!) * 1000000).ceil(),
            ),
          ),
  );
  final requestTilePort = await tileQueue.next as SendPort;

  // Start progress tracking
  final initialDownloadProgress = DownloadProgress._initial(
    maxTilesCount: maxTiles,
    tilesPerSecondLimit: input.rateLimit,
    retryFailedRequestTiles: input.retryFailedRequestTiles,
  );
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
  void sendToMain(Object? m) => input.sendPort.send(m);

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
          sendToMain(_DownloadManagerControlCmd.pause);
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
              sendToMain(
                lastDownloadProgress = lastDownloadProgress._updateWithoutTile(
                  elapsedDuration: downloadDuration.elapsed,
                  tilesPerSecond: getCurrentTPS(registerNewTPS: false),
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
      endTile: min(input.region.end ?? largestInt, maxTiles),
    );
  }

  // Create convienience method to update recovery system if enabled
  void updateRecovery() {
    if (input.recoveryId case final recoveryId?) {
      input.backend.updateRecovery(
        id: recoveryId,
        newStartTile: 1 + lastDownloadProgress.flushedTilesCount,
      );
    }
  }

  // Duplicate the backend to make it safe to send through isolates
  final threadBackend = input.backend.duplicate();

  // Now it's safe, start accepting communications from the root
  sendToMain(rootReceivePort.sendPort);

  // Send an initial progress report to indicate the start of the download
  sendToMain(initialDownloadProgress);

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
            urlTransformer: input.urlTransformer,
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
              // Handles case when cancel is emitted before thread is setup
              .then((_) => sendPortCompleter.future)
              .then((s) => s.send(null)),
        );

        downloadThreadReceivePort.listen(
          (evt) async {
            // Thread is sending tile data
            if (evt is TileEvent) {
              // Send event to user
              sendToMain(evt);

              // Queue tiles for retry if failed and not already a retry attempt
              if (input.retryFailedRequestTiles &&
                  evt is FailedRequestTileEvent &&
                  !evt.wasRetryAttempt) {
                if (isRetryingTiles) {
                  assert(
                    lastTileRetry == null,
                    'Must not already have a recorded last tile',
                  );
                  lastTileRetry = evt.coordinates;
                } else {
                  retryTiles.add(evt.coordinates);
                }
              }

              // If buffering is in use, send a progress update with buffer info
              if (input.maxBufferLength != 0) {
                // Update correct thread buffer with new tile on success
                if (evt is SuccessfulTileEvent) {
                  if (evt._wasBufferFlushed) {
                    threadBuffersTiles[threadNo] = 0;
                    threadBuffersSize[threadNo] = 0;
                  } else {
                    threadBuffersTiles[threadNo]++;
                    threadBuffersSize[threadNo] += evt.tileImage.lengthInBytes;
                  }
                }

                final wasBufferFlushed =
                    evt is SuccessfulTileEvent && evt._wasBufferFlushed;

                sendToMain(
                  lastDownloadProgress = lastDownloadProgress._updateWithTile(
                    bufferedTiles: evt is SuccessfulTileEvent
                        ? (
                            count: threadBuffersTiles.reduce((a, b) => a + b),
                            size: threadBuffersSize.reduce((a, b) => a + b) /
                                1024,
                          )
                        : null,
                    newTileEvent: evt,
                    elapsedDuration: downloadDuration.elapsed,
                    tilesPerSecond: getCurrentTPS(registerNewTPS: true),
                  ),
                );

                // For efficiency, only update recovery when the buffer is
                // cleaned
                // We don't want to update recovery to a tile that isn't cached
                // (only buffered), because they'll be lost in the events
                // recovery is designed to recover from
                if (wasBufferFlushed) updateRecovery();
              } else {
                // We do not need to care about buffering, which makes updates
                // much easier
                sendToMain(
                  lastDownloadProgress = lastDownloadProgress._updateWithTile(
                    newTileEvent: evt,
                    elapsedDuration: downloadDuration.elapsed,
                    tilesPerSecond: getCurrentTPS(registerNewTPS: true),
                  ),
                );

                updateRecovery();
              }

              return;
            }

            // Thread is requesting new tile coords
            if (evt is int) {
              // If pause requested, mark thread as paused and wait for resume
              if (!pauseResumeSignal.isCompleted) {
                threadPausedStates[threadNo].complete();
                await pauseResumeSignal.future;
              }

              // Request a new tile coord fresh from the generator
              // This is only necessary if we are not retrying tiles, but we
              // just attempt anyway
              requestTilePort.send(null);

              // Wait for a tile coordinate to be generated if available
              final nextCoordinates = (await tileQueue.take(1)).firstOrNull;

              // Kill the thread if no new tiles are available
              if (nextCoordinates == null) return sendPort.send(null);

              // Otherwise, send the coordinate to the thread, marking whether
              // it is a retry tile
              return sendPort.send(
                (
                  tileCoordinates: nextCoordinates,
                  isRetryAttempt: isRetryingTiles,
                ),
              );
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

  // Send final progress update
  downloadDuration.stop();
  sendToMain(
    lastDownloadProgress = lastDownloadProgress._updateToComplete(
      elapsedDuration: downloadDuration.elapsed,
    ),
  );

  // Cleanup resources and shutdown
  fallbackReportTimer?.cancel();
  rootReceivePort.close();
  if (input.recoveryId != null) await input.backend.uninitialise();
  tileIsolate.kill(priority: Isolate.immediate);
  await tileQueue.cancel(immediate: true);
  Isolate.exit();
}
