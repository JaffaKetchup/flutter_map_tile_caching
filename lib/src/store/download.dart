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

  int? _recoveryId;
  // ignore: close_sinks
  StreamController<TileProgress>? _tileProgressStreamController;
  Completer<void>? _cancelRequestSignal;
  Completer<void>? _cancelCompleteSignal;
  InternalProgressTimingManagement? _progressManagement;
  BaseClient? _httpClient;

  factory DownloadManagement._(StoreDirectory storeDirectory) {
    if (!_instances.keys.contains(storeDirectory)) {
      _instances[storeDirectory] = DownloadManagement.__(storeDirectory);
    }
    return _instances[storeDirectory]!;
  }

  DownloadManagement.__(this._storeDirectory);

  /// Contains the intialised instances of [DownloadManagement]s
  static final Map<StoreDirectory, DownloadManagement> _instances = {};

  /// Download a specified [DownloadableRegion] in the foreground, with a
  /// recovery session
  ///
  /// To check the number of tiles that need to be downloaded before using this
  /// function, use [check].
  ///
  /// [httpClient] defaults to a [HttpPlusClient] which supports HTTP/2 and falls
  /// back to a standard [IOClient]/[HttpClient] for HTTP/1.1 servers. Timeout is
  /// set to 5 seconds by default.
  ///
  /// Streams a [DownloadProgress] object containing statistics and information
  /// about the download's progression status. This must be listened to.
  ///
  /// ---
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
  Stream<DownloadProgress> startForeground({
    required DownloadableRegion region,
    FMTCTileProviderSettings? tileProviderSettings,
    bool disableRecovery = false,
    DownloadBufferMode bufferMode = DownloadBufferMode.disabled,
    int? bufferLimit,
    BaseClient? httpClient,
  }) async* {
    // Start recovery
    _recoveryId = DateTime.now().millisecondsSinceEpoch;
    if (!disableRecovery) {
      await FMTC.instance.rootDirectory.recovery._start(
        id: _recoveryId!,
        storeName: _storeDirectory.storeName,
        region: region,
      );
    }

    // Count number of tiles
    final maxTiles = await check(region);

    // Get the tile provider
    final FMTCTileProvider tileProvider =
        _storeDirectory.getTileProvider(tileProviderSettings);

    // Initialise HTTP client
    _httpClient = httpClient ??
        HttpPlusClient(
          http1Client: IOClient(
            HttpClient()
              ..connectionTimeout = const Duration(seconds: 5)
              ..userAgent = null,
          ),
          connectionTimeout: const Duration(seconds: 5),
        );

    // Initialise the sea tile removal system
    Uint8List? seaTileBytes;
    if (region.seaTileRemoval) {
      try {
        seaTileBytes = (await _httpClient!.get(
          Uri.parse(
            tileProvider.getTileUrl(
              const TileCoordinates(0, 0, 17),
              region.options,
            ),
          ),
        ))
            .bodyBytes;
      } catch (e) {
        seaTileBytes = null;
      }
    }

    // Initialise variables
    final List<String> failedTiles = [];
    int bufferedTiles = 0;
    int bufferedSize = 0;
    int persistedTiles = 0;
    int persistedSize = 0;
    int seaTiles = 0;
    int existingTiles = 0;
    _tileProgressStreamController = StreamController();
    _cancelRequestSignal = Completer();
    _cancelCompleteSignal = Completer();

    // Start progress management
    final DateTime startTime = DateTime.now();
    _progressManagement = InternalProgressTimingManagement()..start();

    // Start writing isolates
    await BulkTileWriter.start(
      provider: tileProvider,
      bufferMode: bufferMode,
      bufferLimit: bufferLimit,
      directory: FMTC.instance.rootDirectory.directory.absolute.path,
      streamController: _tileProgressStreamController!,
    );

    // Start the bulk downloader
    final Stream<TileProgress> downloadStream = await bulkDownloader(
      streamController: _tileProgressStreamController!,
      cancelRequestSignal: _cancelRequestSignal!,
      cancelCompleteSignal: _cancelCompleteSignal!,
      region: region,
      provider: tileProvider,
      seaTileBytes: seaTileBytes,
      progressManagement: _progressManagement!,
      client: _httpClient!,
    );

    // Listen to download progress, and report results
    await for (final TileProgress evt in downloadStream) {
      if (evt.failedUrl == null) {
        if (!evt.wasCancelOperation) {
          bufferedTiles++;
        } else {
          bufferedTiles = 0;
        }
        bufferedSize += evt.sizeBytes;
        if (evt.bulkTileWriterResponse != null) {
          persistedTiles = evt.bulkTileWriterResponse![0];
          persistedSize = evt.bulkTileWriterResponse![1];
        }
      } else {
        failedTiles.add(evt.failedUrl!);
      }

      if (evt.wasSeaTile) seaTiles += 1;
      if (evt.wasExistingTile) existingTiles += 1;

      final DownloadProgress prog = DownloadProgress._(
        downloadID: _recoveryId!,
        maxTiles: maxTiles,
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
      if (prog.percentageProgress >= 100) break;
    }

    _internalCancel();
  }

  /// Check approximately how many downloadable tiles are within a specified
  /// [DownloadableRegion]
  ///
  /// This does not take into account sea tile removal or redownload prevention,
  /// as these are handled in the download area of the code.
  ///
  /// Returns an `int` which is the number of tiles.
  Future<int> check(DownloadableRegion region) => compute(
        region.when(
          rectangle: (_) => TilesCounter.rectangleTiles,
          circle: (_) => TilesCounter.circleTiles,
          line: (_) => TilesCounter.lineTiles,
        ),
        region,
      );

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
  Future<void> cancel() async {
    _cancelRequestSignal?.complete();
    await _cancelCompleteSignal?.future;

    _internalCancel();
  }

  void _internalCancel() {
    _progressManagement?.stop();

    if (_recoveryId != null) {
      FMTC.instance.rootDirectory.recovery.cancel(_recoveryId!);
    }
    _httpClient?.close();

    _instances.remove(_storeDirectory);
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
