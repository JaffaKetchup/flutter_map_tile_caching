// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides bulk downloading functionality for a specific [FMTCStore]
///
/// ---
///
/// {@template num_instances}
/// By default, only one download is allowed at any one time, across all stores.
///
/// However, if necessary, multiple can be started by setting methods'
/// `instanceId` argument to a unique value on methods. Whatever object
/// `instanceId` is, it must have a valid and useful equality and `hashCode`
/// implementation, as it is used as the key in a `Map`. Note that this unique
/// value must be known and remembered to control the state of the download.
/// Note that instances are shared across all stores.
///
/// > [!WARNING]
/// > Starting multiple simultaneous downloads may lead to a noticeable
/// > performance loss. Ensure you thoroughly test and profile your application.
/// {@endtemplate}
///
/// ---
///
/// Does not keep state. State and download instances are held internally by
/// [DownloadInstance].
@immutable
class StoreDownload {
  const StoreDownload._(this._storeName);
  final String _storeName;

  /// Download a specified [DownloadableRegion] in the foreground, with a
  /// recovery session by default
  ///
  /// > [!TIP]
  /// > To count the number of tiles in a region before starting a download, use
  /// > [countTiles].
  ///
  /// ---
  ///
  /// Outputs two non-broadcast streams.
  ///
  /// One emits [DownloadProgress]s which contain stats and info about the whole
  /// download.
  ///
  /// One emits [TileEvent]s which contain info about the most recent tile
  /// attempted only.
  ///
  /// The first stream (of [DownloadProgress]s) will emit events:
  ///  * once per [TileEvent] emitted on the second stream
  ///  * at intervals of no longer than [maxReportInterval]
  ///  * once at the start of the download indicating setup is complete and the
  ///    first tile is being downloaded
  ///  * once additionally at the end of the download after the last tile
  ///    setting some final statistics (such as tiles per second to 0)
  ///
  /// Once the stream of [DownloadProgress]s completes/finishes, the download
  /// has stopped.
  ///
  /// Neither output stream respects listen, pause, resume, or cancel events
  /// when submitted through the stream subscription.
  /// The download will start when this method is invoked, irrespective of
  /// whether there are listeners. The download will continue irrespective of
  /// listeners. The only control methods are via FMTC's [pause], [resume], and
  /// [cancel] methods.
  ///
  /// ---
  ///
  /// There are multiple options available to improve the speed of the download.
  /// These are ordered from most impact to least impact.
  ///
  /// - [parallelThreads] (defaults to 5 | 1 to disable): number of simultaneous
  /// download threads to run
  /// - [maxBufferLength] (defaults to 200 | 0 to disable): number of tiles to
  /// temporarily buffer before writing to the store (split evenly between
  /// [parallelThreads])
  /// - [skipExistingTiles] (defaults to `false`): whether to skip downloading
  /// tiles that are already cached
  /// - [skipSeaTiles] (defaults to `true`): whether to skip caching tiles that
  /// are entirely sea (based on a comparison to the tile at x0,y0,z17)
  ///
  /// > [!WARNING]
  /// > Using too many parallel threads may place significant strain on the tile
  /// > server, so check your tile server's ToS for more information.
  ///
  /// > [!WARNING]
  /// > Using buffering will mean that an unexpected forceful quit (such as an
  /// > app closure, [cancel] is safe) will result in losing the tiles that are
  /// > currently in the buffer. It will also increase the memory (RAM)
  /// > required.
  ///
  /// > [!WARNING]
  /// > Skipping sea tiles will not reduce the number of downloads - tiles must
  /// > be downloaded to be compared against the sample sea tile. It is only
  /// > designed to reduce the storage capacity consumed.
  ///
  /// ---
  ///
  /// Although disabled `null` by default, [rateLimit] can be used to impose a
  /// limit on the maximum number of tiles that can be attempted per second.
  /// This is useful to avoid placing too much strain on tile servers and avoid
  /// external rate limiting. Note that the [rateLimit] is only approximate.
  /// Also note that all tile attempts are rate limited, even ones that do not
  /// need a server request.
  ///
  /// To check whether the current [DownloadProgress.tilesPerSecond] statistic
  /// is currently limited by [rateLimit], check
  /// [DownloadProgress.isTPSArtificiallyCapped].
  ///
  /// ---
  ///
  /// If [retryFailedRequestTiles] is enabled (as is by default), tiles that
  /// fail to  download due to a failed request ONLY ([FailedRequestTileEvent])
  /// will be queued and retried once after all remaining tiles have been
  /// attempted.
  /// This does not retry tiles that failed under [NegativeResponseTileEvent],
  /// as the response from the server in these cases will likely indicate that
  /// the issue is unlikely to be resolved shortly enough for a retry to succeed
  /// (for example, 404 Not Found tiles are unlikely to ever exist).
  ///
  /// ---
  ///
  /// A fresh [DownloadProgress] event will always be emitted every
  /// [maxReportInterval] (if specified), which defaults to every 1 second,
  /// regardless of whether any more tiles have been attempted/downloaded/failed.
  /// This is to enable the [DownloadProgress.elapsedDuration] to be accurately
  /// presented to the end user.
  ///
  /// {@macro fmtc.tileevent.extraConsiderations}
  ///
  /// ---
  ///
  /// When this download is started, assuming [disableRecovery] is `false` (as
  /// default), the recovery system will register this download, to allow it to
  /// be recovered if it unexpectedly fails.
  ///
  /// For more info, see [RootRecovery].
  ///
  /// ---
  ///
  /// For info about [urlTransformer], see [FMTCTileProvider.urlTransformer].
  /// If unspecified, and the [region]'s [DownloadableRegion.options] is an
  /// [FMTCTileProvider], will default to that tile provider's `urlTransformer`
  /// if specified. Otherwise, will default to the identity function.
  ///
  /// To set additional headers, set it via [TileProvider.headers] when
  /// constructing the [DownloadableRegion].
  ///
  /// ---
  ///
  /// {@macro num_instances}
  ({
    Stream<TileEvent> tileEvents,
    Stream<DownloadProgress> downloadProgress,
  }) startForeground({
    required DownloadableRegion region,
    int parallelThreads = 5,
    int maxBufferLength = 200,
    bool skipExistingTiles = false,
    bool skipSeaTiles = true,
    int? rateLimit,
    bool retryFailedRequestTiles = true,
    Duration? maxReportInterval = const Duration(seconds: 1),
    bool disableRecovery = false,
    UrlTransformer? urlTransformer,
    Object instanceId = 0,
  }) {
    FMTCBackendAccess.internal; // Verify initialisation

    // Verify input arguments
    if (!(region.options.wmsOptions != null ||
        region.options.urlTemplate != null)) {
      throw ArgumentError(
        "`.toDownloadable`'s `TileLayer` argument must specify an appropriate "
            '`urlTemplate` or `wmsOptions`',
        'region.options.urlTemplate',
      );
    }
    if (parallelThreads < 1) {
      throw ArgumentError.value(
        parallelThreads,
        'parallelThreads',
        'must be 1 or greater',
      );
    }
    if (maxBufferLength < 0) {
      throw ArgumentError.value(
        maxBufferLength,
        'maxBufferLength',
        'must be 0 or greater',
      );
    }
    if ((rateLimit ?? 2) < 1) {
      throw ArgumentError.value(
        rateLimit,
        'rateLimit',
        'must be 1 or greater, or null',
      );
    }

    final UrlTransformer resolvedUrlTransformer;
    if (urlTransformer != null) {
      resolvedUrlTransformer = urlTransformer;
    } else {
      if (region.options.tileProvider
          case final FMTCTileProvider tileProvider) {
        resolvedUrlTransformer = tileProvider.urlTransformer;
      } else {
        resolvedUrlTransformer = (u) => u;
      }
    }

    // Create download instance
    final instance = DownloadInstance.registerIfAvailable(instanceId);
    if (instance == null) {
      throw StateError(
        'A download instance with ID $instanceId already exists\nTo start '
        'another download simultaneously, use a unique `instanceId`. Read the '
        'documentation for additional considerations that should be taken.',
      );
    }

    // Generate recovery ID (unless disabled)
    final recoveryId = disableRecovery
        ? null
        : Object.hash(instanceId, DateTime.timestamp().millisecondsSinceEpoch);
    if (!disableRecovery) FMTCRoot.recovery._downloadsOngoing.add(recoveryId!);

    // Prepare output streams
    final tileEventsStreamController = StreamController<TileEvent>();
    final downloadProgressStreamController =
        StreamController<DownloadProgress>();

    () async {
      // Start download thread
      final receivePort = ReceivePort();
      await Isolate.spawn(
        _downloadManager,
        (
          sendPort: receivePort.sendPort,
          region: region,
          storeName: _storeName,
          parallelThreads: parallelThreads,
          maxBufferLength: maxBufferLength,
          skipExistingTiles: skipExistingTiles,
          skipSeaTiles: skipSeaTiles,
          maxReportInterval: maxReportInterval,
          rateLimit: rateLimit,
          retryFailedRequestTiles: retryFailedRequestTiles,
          urlTransformer: resolvedUrlTransformer,
          recoveryId: recoveryId,
          backend: FMTCBackendAccessThreadSafe.internal,
        ),
        onExit: receivePort.sendPort,
        debugName: '[FMTC] Master Bulk Download Thread',
      );

      // Setup control mechanisms (completers)
      final cancelCompleter = Completer<void>();
      Completer<void>? pauseCompleter;

      await for (final evt in receivePort) {
        // Handle new download progress
        if (evt is DownloadProgress) {
          downloadProgressStreamController.add(evt);
          continue;
        }

        // Handle new tile event
        if (evt is TileEvent) {
          tileEventsStreamController.add(evt);
          continue;
        }

        // Handle pause comms
        if (evt == _DownloadManagerControlCmd.pause) {
          pauseCompleter?.complete();
          continue;
        }

        // Handle shutdown (both normal and cancellation)
        if (evt == null) break;

        // Setup control mechanisms (senders)
        if (evt is SendPort) {
          instance
            ..requestCancel = () {
              evt.send(_DownloadManagerControlCmd.cancel);
              return cancelCompleter.future;
            }
            ..requestPause = () {
              evt.send(_DownloadManagerControlCmd.pause);
              // Completed by handler above
              return (pauseCompleter = Completer()).future
                ..then((_) => instance.isPaused = true);
            }
            ..requestResume = () {
              evt.send(_DownloadManagerControlCmd.resume);
              instance.isPaused = false;
            };
          continue;
        }

        throw UnimplementedError('Unrecognised message');
      }

      // Handle shutdown (both normal and cancellation)
      receivePort.close();
      if (!disableRecovery) await FMTCRoot.recovery.cancel(recoveryId!);
      DownloadInstance.unregister(instanceId);
      cancelCompleter.complete();
      unawaited(tileEventsStreamController.close());
      unawaited(downloadProgressStreamController.close());
    }();

    return (
      tileEvents: tileEventsStreamController.stream,
      downloadProgress: downloadProgressStreamController.stream,
    );
  }

  /// Count the number of tiles within the specified region
  ///
  /// This does not include skipped sea tiles or skipped existing tiles, as
  /// those are handled during a download (as the contents must be known).
  ///
  /// Note that this does not require an existing/ready store, or a sensical
  /// [DownloadableRegion.options].
  Future<int> countTiles(DownloadableRegion region) => compute(
        (region) => region.when(
          rectangle: TileCounters.rectangleTiles,
          circle: TileCounters.circleTiles,
          line: TileCounters.lineTiles,
          customPolygon: TileCounters.customPolygonTiles,
          multi: TileCounters.multiTiles,
        ),
        region,
      );

  /// Count the number of tiles within the specified region
  ///
  /// This does not include skipped sea tiles or skipped existing tiles, as
  /// those are handled during a download (as the contents must be known).
  ///
  /// Note that this does not require an existing/ready store, or a sensical
  /// [DownloadableRegion.options].
  @Deprecated('`check` has been renamed to `countTiles`')
  Future<int> check(DownloadableRegion region) => countTiles(region);

  /// Cancel the ongoing foreground download and recovery session
  ///
  /// Will return once the cancellation is complete. Note that all running
  /// parallel download threads will be allowed to finish their *current* tile
  /// download, and buffered tiles will be written. There is no facility to
  /// cancel the download immediately, as this would likely cause unwanted
  /// behaviour.
  ///
  /// {@macro num_instances}
  ///
  /// Does nothing (returns immediately) if there is no ongoing download.
  Future<void> cancel({Object instanceId = 0}) async =>
      await DownloadInstance.get(instanceId)?.requestCancel?.call();

  /// Pause the ongoing foreground download
  ///
  /// Use [resume] to resume the download. It is also safe to use [cancel]
  /// without resuming first.
  ///
  /// Will return once the pause operation is complete. Note that all running
  /// parallel download threads will be allowed to finish their *current* tile
  /// download. Any buffered tiles are not written.
  ///
  /// {@macro num_instances}
  ///
  /// Does nothing (returns immediately) if there is no ongoing download or the
  /// download is already paused.
  Future<void> pause({Object instanceId = 0}) async {
    final instance = DownloadInstance.get(instanceId);
    if (instance == null || instance.isPaused) return;
    await instance.requestPause!.call();
  }

  /// Resume (after a [pause]) the ongoing foreground download
  ///
  /// {@macro num_instances}
  ///
  /// Does nothing if there is no ongoing download or the download is already
  /// running.
  void resume({Object instanceId = 0}) {
    final instance = DownloadInstance.get(instanceId);
    if (instance == null || !instance.isPaused) return;
    instance.requestResume!.call();
  }

  /// Whether the ongoing foreground download is currently paused after a call
  /// to [pause] (and prior to [resume])
  ///
  /// {@macro num_instances}
  ///
  /// Also returns `false` if there is no ongoing download.
  bool isPaused({Object instanceId = 0}) =>
      DownloadInstance.get(instanceId)?.isPaused ?? false;
}
