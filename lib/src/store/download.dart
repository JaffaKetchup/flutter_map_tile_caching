// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides bulk downloading functionality for a specific [FMTCStore]
///
/// ---
///
/// {@template fmtc.bulkDownload.numInstances}
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
  /// Outputs two non-broadcast streams. One emits [DownloadProgress]s which
  /// contain stats and info about the whole download. The other emits
  /// [TileEvent]s which contain info about the most recent tile attempted only.
  /// They only emit events when listened to.
  ///
  /// The first stream (of [DownloadProgress]s) will emit events:
  ///  * once per [TileEvent] emitted on the second stream
  ///  * additionally at intervals of no longer than [maxReportInterval]
  ///    (defaulting to 1 second, to allow time-based statistics to remain
  ///    up-to-date if no [TileEvent]s are emitted for a while)
  ///  * additionally once at the start of the download indicating setup is
  ///    complete and the first tile is being downloaded
  ///  * additionally once at the end of the download after the last tile
  ///    setting some final statistics (such as tiles per second to 0)
  ///  * additionally when pausing and resuming the download, as well as after
  ///    listening to the stream
  ///
  /// The completion/finish of the [DownloadProgress] stream implies the
  /// completion of the download, even if the last
  /// [DownloadProgress.percentageProgress] is not 100(%).
  ///
  /// The second stream (of [TileEvent]s) will emit events for every tile
  /// download attempt.
  ///
  /// > [!IMPORTANT]
  /// >
  /// > An emitted [TileEvent] may refer to a tile for which an event has been
  /// > emitted previously.
  /// >
  /// > This will be the case when [TileEvent.wasRetryAttempt] is `true`, which
  /// > may occur only if [retryFailedRequestTiles] is enabled.
  ///
  /// Listening, pausing, resuming, or cancelling subscriptions to the output
  /// streams will not start, pause, resume, or cancel the download. It will
  /// only change the output stream. Not listening to a stream may improve the
  /// efficiency of the download a negligible amount.
  ///
  /// To control the download itself, use [pause], [resume], and [cancel].
  ///
  /// The download starts when this method is invoked: it does not wait for
  /// listneners.
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
  /// > [!IMPORTANT]
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
  /// When this download is started, assuming [disableRecovery] is `false` (as
  /// default), the recovery system will register this download, to allow it to
  /// be recovered if it unexpectedly fails.
  ///
  /// For more info, see [RootRecovery].
  ///
  /// ---
  ///
  /// For info about [urlTransformer], see [FMTCTileProvider.urlTransformer] and
  /// the
  /// [online documentation](https://fmtc.jaffaketchup.dev/basic-usage/integrating-with-a-map#ensure-tiles-are-resilient-to-url-changes).
  ///
  /// > [!WARNING]
  /// >
  /// > The callback will be passed to a different isolate: therefore, avoid
  /// > using any external state that may not be properly captured or cannot be
  /// > copied to an isolate spawned with [Isolate.spawn] (see [SendPort.send]).
  /// >
  /// > Ideally, the callback should be state-indepedent.
  ///
  /// If unspecified, and the [region]'s [DownloadableRegion.options]
  /// [TileLayer.tileProvider] is a [FMTCTileProvider] with a defined
  /// [FMTCTileProvider.urlTransformer], this will default to that transformer.
  /// Otherwise, will default to the identity function.
  ///
  /// ---
  ///
  /// To set additional headers, set it via [TileProvider.headers] when
  /// constructing the [DownloadableRegion].
  ///
  /// ---
  ///
  /// {@macro fmtc.bulkDownload.numInstances}
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
    } else if (region.options.tileProvider
        case final FMTCTileProvider tileProvider) {
      resolvedUrlTransformer = tileProvider.urlTransformer ?? (u) => u;
    } else {
      resolvedUrlTransformer = (u) => u;
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

    // Prepare send port completer
    // We use a completer to ensure that the user's request is met as soon as
    // possible and is not dropped if the download has not setup yet
    final sendPortCompleter = Completer<SendPort>();

    // Prepare output streams
    // The statuses of the output streams does not control the download itself,
    // but for efficiency, we don't emit events that the user will not hear
    // We do not filter in the main thread, for added efficiency, we instead
    // make the decision directly at source, so copying between Isolates is
    // avoided if unnecessary
    // We treat listen & resume and cancel & pause as the same event
    final downloadProgressStreamController = StreamController<DownloadProgress>(
      onListen: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.startEmittingDownloadProgress),
      onResume: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.startEmittingDownloadProgress),
      onPause: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.stopEmittingDownloadProgress),
      onCancel: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.stopEmittingDownloadProgress),
    );
    final tileEventsStreamController = StreamController<TileEvent>(
      onListen: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.startEmittingTileEvents),
      onResume: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.startEmittingTileEvents),
      onPause: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.stopEmittingTileEvents),
      onCancel: () async => (await sendPortCompleter.future)
          .send(_DownloadManagerControlCmd.stopEmittingTileEvents),
    );

    // Prepare control mechanisms
    final cancelCompleter = Completer<void>();
    Completer<void>? pauseCompleter;
    sendPortCompleter.future.then(
      (sp) => instance
        ..requestCancel = () {
          sp.send(_DownloadManagerControlCmd.cancel);
          return cancelCompleter.future;
        }
        ..requestPause = () {
          sp.send(_DownloadManagerControlCmd.pause);
          // Completed by handler below
          return (pauseCompleter = Completer()).future;
        }
        ..requestResume = () {
          sp.send(_DownloadManagerControlCmd.resume);
          instance.isPaused = false;
        },
    );

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
          sendPortCompleter.complete(evt);
          continue;
        }

        throw UnsupportedError('Unrecognised message: $evt');
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
  @Deprecated(
    'Use `countTiles()` instead. '
    'The new name is less ambiguous and aligns better with recommended Dart '
    'code style. '
    'This feature was deprecated in v10, and will be removed in a future '
    'version.',
  )
  Future<int> check(DownloadableRegion region) => countTiles(region);

  /// Cancel the ongoing foreground download and recovery session
  ///
  /// Will return once the cancellation is complete. Note that all running
  /// parallel download threads will be allowed to finish their *current* tile
  /// download, and buffered tiles will be written. There is no facility to
  /// cancel the download immediately, as this would likely cause unwanted
  /// behaviour.
  ///
  /// {@macro fmtc.bulkDownload.numInstances}
  ///
  /// Does nothing (returns immediately) if there is no ongoing download.
  Future<void> cancel({Object instanceId = 0}) async =>
      await DownloadInstance.get(instanceId)?.requestCancel?.call();

  /// Pause the ongoing foreground download
  ///
  /// Use [resume] to resume the download. It is also safe to use [cancel]
  /// without resuming first.
  ///
  /// Note that all running parallel download threads will be allowed to finish
  /// their *current* tile download before pausing.
  ///
  /// It is not usually necessary to use the result. Returns `null` if there is
  /// no ongoing download or the download is already paused or pausing.
  /// Otherwise returns whether the download was paused (`false` if [resume] is
  /// called whilst the download is being paused).
  ///
  /// Any buffered tiles are not flushed.
  ///
  /// ---
  ///
  /// {@macro fmtc.bulkDownload.numInstances}
  Future<bool?> pause({Object instanceId = 0}) {
    final instance = DownloadInstance.get(instanceId);
    if (instance == null ||
        instance.isPaused ||
        !instance.pausingCompleter.isCompleted ||
        instance.requestPause == null) {
      return SynchronousFuture(null);
    }

    instance
      ..pausingCompleter = Completer()
      ..resumingAfterPause = Completer();

    instance.requestPause!().then((_) {
      instance.pausingCompleter.complete(true);
      if (!instance.resumingAfterPause!.isCompleted) instance.isPaused = true;
      instance.resumingAfterPause = null;
    });

    return Future.any(
      [instance.resumingAfterPause!.future, instance.pausingCompleter.future],
    );
  }

  /// Resume (after a [pause]) the ongoing foreground download
  ///
  /// It is not usually necessary to use the result. Returns `null` if there is
  /// no ongoing download or the download is already running. Returns `true` if
  /// the download was paused. Returns `false` if the download was paus*ing* (
  /// in which case the download will not be paused).
  ///
  /// ---
  ///
  /// {@macro fmtc.bulkDownload.numInstances}
  bool? resume({Object instanceId = 0}) {
    final instance = DownloadInstance.get(instanceId);
    if (instance == null ||
        (!instance.isPaused && instance.resumingAfterPause == null) ||
        instance.requestResume == null) {
      return null;
    }

    if (instance.pausingCompleter.isCompleted) {
      instance.requestResume!();
      return true;
    }

    if (!instance.resumingAfterPause!.isCompleted) {
      instance
        ..resumingAfterPause!.complete(false)
        ..pausingCompleter.future.then((_) => instance.requestResume!());
    }
    return false;
  }

  /// Whether the ongoing foreground download is currently paused after a call
  /// to [pause] (and prior to [resume])
  ///
  /// Also returns `false` if there is no ongoing download.
  ///
  /// ---
  ///
  /// {@macro fmtc.bulkDownload.numInstances}
  bool isPaused({Object instanceId = 0}) =>
      DownloadInstance.get(instanceId)?.isPaused ?? false;
}
