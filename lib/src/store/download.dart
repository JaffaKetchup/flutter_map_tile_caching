// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Provides tools to manage bulk downloading to a specific [StoreDirectory]
///
/// Is a singleton to ensure functioning as expected.
///
/// The 'fmtc_plus_background_downloading' module must be installed to add the
/// background downloading functionality.
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
  InternalProgressTimingManagement? _progressManagement;

  /// Provides tools to manage bulk downloading to a specific [StoreDirectory]
  ///
  /// Is a singleton to ensure functioning as expected.
  ///
  /// The 'fmtc_plus_background_downloading' module must be installed to add the
  /// background downloading functionality.
  factory DownloadManagement._(StoreDirectory storeDirectory) {
    if (!_instances.keys.contains(storeDirectory)) {
      _instances[storeDirectory] = DownloadManagement.__(storeDirectory);
    }
    return _instances[storeDirectory]!;
  }

  /// Provides tools to manage bulk downloading to a specific [StoreDirectory]
  ///
  /// Is a singleton to ensure functioning as expected.
  ///
  /// The 'fmtc_plus_background_downloading' module must be installed to add the
  /// background downloading functionality.
  DownloadManagement.__(this._storeDirectory);

  /// Contains the intialised instances of [DownloadManagement]s
  static final Map<StoreDirectory, DownloadManagement> _instances = {};

  /// Download a specified [DownloadableRegion] in the foreground
  ///
  /// To check the number of tiles that need to be downloaded before using this
  /// function, use [check].
  ///
  /// Unless otherwise specified in [disableRecovery], a recovery session is
  /// started.
  ///
  /// [bufferMode] and [bufferLimit] control how this download will use
  /// buffering. For information about buffering, and it's advantages and
  /// disadvantages, see
  /// [this docs page](https://fmtc.jaffaketchup.dev/bulk-downloading/foreground/buffering).
  /// Also see [DownloadBufferMode]'s documentation.
  ///
  /// - If [bufferMode] is [DownloadBufferMode.disabled] (default), [bufferLimit]
  /// will be ignored
  /// - If [bufferMode] is [DownloadBufferMode.tiles], [bufferLimit] will default
  /// to 500
  /// - If [bufferMode] is [DownloadBufferMode.bytes], [bufferLimit] will default
  /// to 2000000 (2 MB)
  ///
  /// Note that these defaults may not be suitable for your user's devices, and
  /// you should adjust them to be suitable to your usecase.
  ///
  /// Streams a [DownloadProgress] object containing statistics and information
  /// about the download's progression status.
  Stream<DownloadProgress> startForeground({
    required DownloadableRegion region,
    FMTCTileProviderSettings? tileProviderSettings,
    bool disableRecovery = false,
    DownloadBufferMode bufferMode = DownloadBufferMode.disabled,
    int? bufferLimit,
    BaseClient? httpClient,
  }) async* {
    _recoveryId = DateTime.now().millisecondsSinceEpoch;

    if (!disableRecovery) {
      await FMTC.instance.rootDirectory.recovery._start(
        id: _recoveryId!,
        storeName: _storeDirectory.storeName,
        region: region,
      );
    }

    yield* _startDownload(
      tileProviderSettings: tileProviderSettings,
      region: region,
      tiles: await _generateTilesComputer(region),
      bufferMode: bufferMode,
      bufferLimit: bufferLimit,
      httpClient: httpClient,
    );
  }

  /// Check approximately how many downloadable tiles are within a specified
  /// [DownloadableRegion]
  ///
  /// This does not take into account sea tile removal or redownload prevention,
  /// as these are handled in the download area of the code.
  ///
  /// Returns an `int` which is the number of tiles.
  Future<int> check(DownloadableRegion region) async =>
      (await _generateTilesComputer(region)).length;

  /// Cancels the ongoing foreground download and recovery session (within the
  /// current object)
  ///
  /// Do not use to cancel background downloads, return `true` from the
  /// background download callback to cancel a background download. Background
  /// download cancellations require a few more 'shut-down' steps that can create
  /// unexpected issues and memory leaks if not carried out.
  ///
  /// Note that another instance of this object must be retrieved before another
  /// download is attempted, as this one is destroyed.
  Future<void> cancel({Uint8List? latestTileImage}) async {
    await BulkTileWriter.stop(latestTileImage);
    _queue?.dispose();
    unawaited(_streamController?.close());
    await _progressManagement?.stopTracking();

    if (_recoveryId != null) {
      await FMTC.instance.rootDirectory.recovery.cancel(_recoveryId!);
    }

    _instances.remove(_storeDirectory);
  }

  Stream<DownloadProgress> _startDownload({
    required FMTCTileProviderSettings? tileProviderSettings,
    required DownloadableRegion region,
    required List<Coords<num>> tiles,
    required DownloadBufferMode bufferMode,
    required int? bufferLimit,
    required BaseClient? httpClient,
  }) async* {
    httpClient ??= HttpPlusClient(
      http1Client: IOClient(
        HttpClient()
          ..connectionTimeout = const Duration(seconds: 5)
          ..userAgent = null,
      ),
      connectionTimeout: const Duration(seconds: 5),
    );

    final FMTCTileProvider tileProvider =
        _storeDirectory.getTileProvider(tileProviderSettings);

    Uint8List? seaTileBytes;
    if (region.seaTileRemoval) {
      try {
        seaTileBytes = (await httpClient.get(
          Uri.parse(
            tileProvider.getTileUrl(Coords(0, 0)..z = 17, region.options),
          ),
        ))
            .bodyBytes;
      } catch (e) {
        seaTileBytes = null;
      }
    }

    int bufferedTiles = 0;
    int bufferedSize = 0;
    int persistedTiles = 0;
    int persistedSize = 0;

    int seaTiles = 0;
    int existingTiles = 0;

    final List<String> failedTiles = [];

    final DateTime startTime = DateTime.now();

    _progressManagement = InternalProgressTimingManagement()..startTracking();

    await BulkTileWriter.start(
      provider: tileProvider,
      bufferMode: bufferMode,
      bufferLimit: bufferLimit,
      downloadStream: _streamController!,
    );

    final Stream<TileProgress> downloadStream = bulkDownloader(
      tiles: tiles,
      provider: tileProvider,
      options: region.options,
      client: httpClient,
      parallelThreads: region.parallelThreads,
      errorHandler: region.errorHandler,
      preventRedownload: region.preventRedownload,
      seaTileBytes: seaTileBytes,
      queue: _queue = Queue(parallel: region.parallelThreads),
      streamController: _streamController = StreamController(),
      downloadID: _recoveryId!,
      progressManagement: _progressManagement!,
    );

    await for (final TileProgress evt in downloadStream) {
      if (evt.failedUrl == null) {
        if (!evt.wasCancelOperation) bufferedTiles++;
        bufferedSize += evt.sizeBytes;
        if (evt.bulkTileWriterResponse != null) {
          persistedTiles = evt.bulkTileWriterResponse![0];
          persistedSize = evt.bulkTileWriterResponse![1];
        }
      } else {
        failedTiles.add(evt.failedUrl!);
      }

      seaTiles += evt.wasSeaTile ? 1 : 0;
      existingTiles += evt.wasExistingTile ? 1 : 0;

      final DownloadProgress prog = DownloadProgress._(
        downloadID: _recoveryId!,
        maxTiles: tiles.length,
        successfulTiles: bufferedTiles,
        persistedTiles: persistedTiles,
        failedTiles: failedTiles,
        successfulSize: bufferedSize / 1024,
        persistedSize: persistedSize / 1024,
        seaTiles: seaTiles,
        existingTiles: existingTiles,
        duration: DateTime.now().difference(startTime),
        tileImage: evt.tileImage == null ? null : MemoryImage(evt.tileImage!),
        bufferMode: bufferMode,
        progressManagement: _progressManagement!,
      );

      yield prog;
      if (prog.percentageProgress >= 100) {
        await cancel(latestTileImage: evt.tileImage);
      }
    }

    httpClient.close();
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
        'rectOutline': LatLngBounds.fromPoints(region.points.cast()),
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

/// Describes the buffering mode during a bulk download
///
/// For information about buffering, and it's advantages and disadvantages, see
/// [this docs page](https://fmtc.jaffaketchup.dev/bulk-downloading/foreground/buffering).
enum DownloadBufferMode {
  /// Disable the buffer (use direct writing)
  ///
  /// Tiles will be written directly to the database as soon as they are
  /// downloaded.
  disabled,

  /// Set the limit of the buffer in terms of the number of tiles it holds
  ///
  /// Tiles will be written to an intermediate memory buffer, then bulk written
  /// to the database once there are more tiles than specified.
  tiles,

  /// Set the limit of the buffer in terms of the number of bytes it holds
  ///
  /// Tiles will be written to an intermediate memory buffer, then bulk written
  /// to the database once there are more bytes than specified.
  bytes,
}

extension _ListExtensionsE<E> on List<E> {
  Iterable<List<E>> chunked(int size) sync* {
    for (var i = 0; i < length; i += size) {
      yield sublist(i, (i + size < length) ? i + size : length);
    }
  }
}
