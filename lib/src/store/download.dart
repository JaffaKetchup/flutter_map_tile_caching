// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides bulk downloading functionality for a specific [FMTCStore]
///
/// ---
///
/// {@template num_instances}
/// By default, only one download is allowed at any one time.
///
/// However, if necessary, multiple can be started by setting methods'
/// `instanceId` argument to a unique value on methods. Whatever object
/// `instanceId` is, it must have a valid and useful equality and `hashCode`
/// implementation, as it is used as the key in a `Map`. Note that this unique
/// value must be known and remembered to control the state of the download.
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
  /// > To check the number of tiles in a region before starting a download, use
  /// > [check].
  ///
  /// Streams a [DownloadProgress] object containing statistics and information
  /// about the download's progression status, once per tile and at intervals
  /// of no longer than [maxReportInterval] (after the first tile).
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
  /// > currently in the buffer. It will also increase the memory (RAM) required.
  ///
  /// > [!WARNING]
  /// > Skipping sea tiles will not reduce the number of downloads - tiles must
  /// > be downloaded to be compared against the sample sea tile. It is only
  /// > designed to reduce the storage capacity consumed.
  ///
  /// ---
  ///
  /// Although disabled `null` by default, [rateLimit] can be used to impose a
  /// limit on the maximum number of tiles that can be attempted per second. This
  /// is useful to avoid placing too much strain on tile servers and avoid
  /// external rate limiting. Note that the [rateLimit] is only approximate. Also
  /// note that all tile attempts are rate limited, even ones that do not need a
  /// server request.
  ///
  /// To check whether the current [DownloadProgress.tilesPerSecond] statistic is
  /// currently limited by [rateLimit], check
  /// [DownloadProgress.isTPSArtificiallyCapped].
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
  /// For information about [urlTransformer], see the documentation on
  /// [FMTCTileProviderSettings.urlTransformer]. Will default to the value in
  /// the default [FMTCTileProviderSettings], else the identity function.
  ///
  /// To set additional headers, set it via [TileProvider.headers] when
  /// constructing the [DownloadableRegion].
  ///
  /// ---
  ///
  /// {@macro num_instances}
  @useResult
  Stream<DownloadProgress> startForeground({
    required DownloadableRegion region,
    int parallelThreads = 5,
    int maxBufferLength = 200,
    bool skipExistingTiles = false,
    bool skipSeaTiles = true,
    int? rateLimit,
    Duration? maxReportInterval = const Duration(seconds: 1),
    bool disableRecovery = false,
    String Function(String)? urlTransformer,
    @Deprecated(
      '`obscuredQueryParams` has been deprecated in favour of `urlTransformer`, '
      'which provides more flexibility.\n'
      'To restore similar functioning, use '
      '`FMTCTileProviderSettings.urlTransformerOmitKeyValues`. Note that this '
      'will apply to the entire URL, not only the query part, which may have '
      'a different behaviour in some rare cases.\n'
      'This argument will be removed in a future version.',
    )
    List<String>? obscuredQueryParams,
    Object instanceId = 0,
  }) async* {
    FMTCBackendAccess.internal; // Verify intialisation

    // Check input arguments for suitability
    if (!(region.options.wmsOptions != null ||
        region.options.urlTemplate != null)) {
      throw ArgumentError(
        "`.toDownloadable`'s `TileLayer` argument must specify an appropriate `urlTemplate` or `wmsOptions`",
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
        urlTransformer: urlTransformer ??
            ((obscuredQueryParams?.isNotEmpty ?? false)
                ? (url) {
                    final components = url.split('?');
                    if (components.length == 1) return url;
                    return '${components[0]}?'
                        '${FMTCTileProviderSettings.urlTransformerOmitKeyValues(
                      url: url,
                      keys: obscuredQueryParams!,
                    )}';
                  }
                : FMTCTileProviderSettings.instance.urlTransformer),
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
      // Handle new progress message
      if (evt is DownloadProgress) {
        yield evt;
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
  }

  /// Check how many downloadable tiles are within a specified region
  ///
  /// This does not include skipped sea tiles or skipped existing tiles, as those
  /// are handled during download only.
  ///
  /// Returns the number of tiles.
  Future<int> check(DownloadableRegion region) => compute(
        region.when(
          rectangle: (_) => TileCounters.rectangleTiles,
          circle: (_) => TileCounters.circleTiles,
          line: (_) => TileCounters.lineTiles,
          customPolygon: (_) => TileCounters.customPolygonTiles,
        ),
        region,
      );

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
  Future<void> pause({Object instanceId = 0}) async =>
      await DownloadInstance.get(instanceId)?.requestPause?.call();

  /// Resume (after a [pause]) the ongoing foreground download
  ///
  /// {@macro num_instances}
  ///
  /// Does nothing if there is no ongoing download or the download is already
  /// running.
  void resume({Object instanceId = 0}) =>
      DownloadInstance.get(instanceId)?.requestResume?.call();

  /// Whether the ongoing foreground download is currently paused after a call
  /// to [pause] (and prior to [resume])
  ///
  /// {@macro num_instances}
  ///
  /// Also returns `false` if there is no ongoing download.
  bool isPaused({Object instanceId = 0}) =>
      DownloadInstance.get(instanceId)?.isPaused ?? false;
}
