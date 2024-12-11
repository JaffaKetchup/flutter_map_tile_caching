// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// Statistics and information about the current progress of the download
///
/// See the documentation on each individual property for more information.
@immutable
class DownloadProgress {
  /// Raw constructor
  ///
  /// Note that [maxTilesCount], [_tilesPerSecondLimit] &
  /// [_retryFailedRequestTiles] are set here (or in
  /// [DownloadProgress._initial]), and are not modified for a download by
  /// update
  @protected
  const DownloadProgress._({
    required this.successfulTilesSize,
    required this.successfulTilesCount,
    required this.bufferedTilesCount,
    required this.bufferedTilesSize,
    required this.seaTilesCount,
    required this.seaTilesSize,
    required this.existingTilesCount,
    required this.existingTilesSize,
    required this.negativeResponseTilesCount,
    required this.failedRequestTilesCount,
    required this.retryTilesQueuedCount,
    required this.maxTilesCount,
    required this.elapsedDuration,
    required this.tilesPerSecond,
    required int? tilesPerSecondLimit,
    required bool retryFailedRequestTiles,
  })  : _tilesPerSecondLimit = tilesPerSecondLimit,
        _retryFailedRequestTiles = retryFailedRequestTiles;

  /// Setup an initial download progress
  ///
  /// Note that [maxTilesCount], [_tilesPerSecondLimit] &
  /// [_retryFailedRequestTiles] are set here (or in [DownloadProgress._]), and
  /// are not modified for a download by update.
  const DownloadProgress._initial({
    required this.maxTilesCount,
    required int? tilesPerSecondLimit,
    required bool retryFailedRequestTiles,
  })  : successfulTilesCount = 0,
        successfulTilesSize = 0,
        bufferedTilesCount = 0,
        bufferedTilesSize = 0,
        seaTilesCount = 0,
        seaTilesSize = 0,
        existingTilesCount = 0,
        existingTilesSize = 0,
        negativeResponseTilesCount = 0,
        failedRequestTilesCount = 0,
        retryTilesQueuedCount = 0,
        elapsedDuration = Duration.zero,
        tilesPerSecond = 0,
        _tilesPerSecondLimit = tilesPerSecondLimit,
        _retryFailedRequestTiles = retryFailedRequestTiles;

  /// Create a new progress object based on the existing one, due to a new tile
  /// event
  ///
  /// [newTileEvent] should be provided for non-[SuccessfulTileEvent]s: this
  /// will be used to automatically update all neccessary statistics.
  ///
  /// For [SuccessfulTileEvent]s, the flushed and buffered metrics cannot be
  /// automatically updated from information in the tile event alone.
  /// [bufferedTiles] should be updated manually.
  ///
  /// [maxTilesCount], [_tilesPerSecondLimit] & [_retryFailedRequestTiles] may
  /// not be modified. [elapsedDuration] & [tilesPerSecond] must always be
  /// modified.
  DownloadProgress _updateWithTile({
    required TileEvent newTileEvent,
    ({int count, double size})? bufferedTiles,
    required Duration elapsedDuration,
    required double tilesPerSecond,
  }) =>
      DownloadProgress._(
        successfulTilesCount: successfulTilesCount +
            (newTileEvent is SuccessfulTileEvent ? 1 : 0),
        successfulTilesSize: successfulTilesSize +
            (newTileEvent is SuccessfulTileEvent
                ? newTileEvent.tileImage.lengthInBytes / 1024
                : 0),
        bufferedTilesCount: bufferedTiles?.count ?? bufferedTilesCount,
        bufferedTilesSize: bufferedTiles?.size ?? bufferedTilesSize,
        seaTilesCount: seaTilesCount + (newTileEvent is SeaTileEvent ? 1 : 0),
        seaTilesSize: seaTilesSize +
            (newTileEvent is SeaTileEvent
                ? newTileEvent.tileImage.lengthInBytes / 1024
                : 0),
        existingTilesCount:
            existingTilesCount + (newTileEvent is ExistingTileEvent ? 1 : 0),
        existingTilesSize: existingTilesSize +
            (newTileEvent is ExistingTileEvent
                ? newTileEvent.tileImage.lengthInBytes / 1024
                : 0),
        negativeResponseTilesCount: negativeResponseTilesCount +
            (newTileEvent is NegativeResponseTileEvent ? 1 : 0),
        failedRequestTilesCount: failedRequestTilesCount +
            (newTileEvent is FailedRequestTileEvent &&
                    (newTileEvent.wasRetryAttempt || !_retryFailedRequestTiles)
                ? 1
                : 0),
        retryTilesQueuedCount: retryTilesQueuedCount +
            (newTileEvent is FailedRequestTileEvent &&
                    _retryFailedRequestTiles &&
                    !newTileEvent.wasRetryAttempt
                ? 1
                : newTileEvent.wasRetryAttempt
                    ? -1
                    : 0),
        maxTilesCount: maxTilesCount,
        elapsedDuration: elapsedDuration,
        tilesPerSecond: tilesPerSecond,
        tilesPerSecondLimit: _tilesPerSecondLimit,
        retryFailedRequestTiles: _retryFailedRequestTiles,
      );

  /// Create a new progress object based on the existing one, without a new tile
  DownloadProgress _updateWithoutTile({
    required Duration elapsedDuration,
    required double tilesPerSecond,
  }) =>
      DownloadProgress._(
        successfulTilesCount: successfulTilesCount,
        successfulTilesSize: successfulTilesSize,
        bufferedTilesCount: bufferedTilesCount,
        bufferedTilesSize: bufferedTilesSize,
        seaTilesCount: seaTilesCount,
        seaTilesSize: seaTilesSize,
        existingTilesCount: existingTilesCount,
        existingTilesSize: existingTilesSize,
        negativeResponseTilesCount: negativeResponseTilesCount,
        failedRequestTilesCount: failedRequestTilesCount,
        retryTilesQueuedCount: retryTilesQueuedCount,
        maxTilesCount: maxTilesCount,
        elapsedDuration: elapsedDuration,
        tilesPerSecond: tilesPerSecond,
        tilesPerSecondLimit: _tilesPerSecondLimit,
        retryFailedRequestTiles: _retryFailedRequestTiles,
      );

  /// Create a new progress object that represents a finished download
  ///
  /// This means [tilesPerSecond] is set to 0, and the buffered statistics are
  /// set to 0.
  DownloadProgress _updateToComplete({
    required Duration elapsedDuration,
  }) =>
      DownloadProgress._(
        successfulTilesCount: successfulTilesCount,
        successfulTilesSize: successfulTilesSize,
        bufferedTilesCount: 0,
        bufferedTilesSize: 0,
        seaTilesCount: seaTilesCount,
        seaTilesSize: seaTilesSize,
        existingTilesCount: existingTilesCount,
        existingTilesSize: existingTilesSize,
        negativeResponseTilesCount: negativeResponseTilesCount,
        failedRequestTilesCount: failedRequestTilesCount,
        retryTilesQueuedCount: retryTilesQueuedCount,
        maxTilesCount: maxTilesCount,
        elapsedDuration: elapsedDuration,
        tilesPerSecond: 0,
        tilesPerSecondLimit: _tilesPerSecondLimit,
        retryFailedRequestTiles: _retryFailedRequestTiles,
      );

  /// The number of tiles remaining to be attempted to download
  ///
  /// This includes [retryTilesQueuedCount] as tiles remaining.
  int get remainingTilesCount =>
      maxTilesCount - (attemptedTilesCount - retryTilesQueuedCount);

  /// The number of tiles that have been attempted to download
  ///
  /// Attempted means they were successful ([successfulTilesCount]), skipped
  /// ([skippedTilesCount]), or failed ([failedTilesCount]). Additionally, this
  /// also includes [retryTilesQueuedCount].
  int get attemptedTilesCount =>
      successfulTilesCount +
      skippedTilesCount +
      failedTilesCount +
      retryTilesQueuedCount;

  /// The number of tiles successfully downloaded (including both tiles buffered
  /// and actually flushed/written to cache)
  ///
  /// This is the number of [SuccessfulTileEvent]s emitted.
  final int successfulTilesCount;

  /// The size in KiB of the tile images successfully downloaded (including both
  /// tiles buffered and actually flushed/written to cache)
  final double successfulTilesSize;

  /// The number of tiles successfully downloaded and written to the cache
  /// (flushed from the buffer)
  int get flushedTilesCount => successfulTilesCount - bufferedTilesCount;

  /// The size in KiB of the tile images successfully downloaded and written to
  /// the cache (flushed from the buffer)
  double get flushedTilesSize => successfulTilesSize - bufferedTilesSize;

  /// The number of tiles successfully downloaded but still to be written to the
  /// cache
  ///
  /// These tiles are volatile and will be lost if the download stops
  /// unexpectedly. However, they will be re-attempted if the download is
  /// recovered.
  final int bufferedTilesCount;

  /// The size in KiB of the tile images successfully downloaded but still to be
  /// written to the cache
  ///
  /// These tiles are volatile and will be lost if the download stops
  /// unexpectedly. However, they will be re-attempted if the download is
  /// recovered.
  final double bufferedTilesSize;

  /// The number of tiles skipped (including both sea tiles and existing tiles,
  /// where their respective options are enabled when starting the download)
  ///
  /// This is the number of [SkippedTileEvent]s emitted.
  int get skippedTilesCount => seaTilesCount + existingTilesCount;

  /// The size in KiB of the tile images skipped (including both sea tiles and
  /// existing tiles, where their respective options are enabled when starting
  /// the download)
  double get skippedTilesSize => seaTilesSize + existingTilesSize;

  /// The number of tiles skipped because they were sea tiles and `skipSeaTiles`
  /// was enabled
  ///
  /// This is the number of [SeaTileEvent]s emitted.
  final int seaTilesCount;

  /// The size in KiB of the tile images skipped because they were sea tiles and
  /// `skipSeaTiles` was enabled
  final double seaTilesSize;

  /// The number of tiles skipped because they already existed in the cache and
  /// `skipExistingTiles` was enabled
  ///
  /// This is the number of [ExistingTileEvent]s emitted.
  final int existingTilesCount;

  /// The size in KiB of the tile images skipped because they already existed in
  /// the cache and `skipExistingTiles` was enabled
  final double existingTilesSize;

  /// The number of tiles that could not be downloaded and are not in the queue
  /// to be retried ([retryTilesQueuedCount])
  ///
  /// See [failedRequestTilesCount] for more information about how that metric
  /// is affected by retry tiles.
  int get failedTilesCount =>
      negativeResponseTilesCount + failedRequestTilesCount;

  /// The number of tiles that could not be downloaded because the HTTP response
  /// was not 200 OK
  ///
  /// This is the number of [NegativeResponseTileEvent]s emitted.
  final int negativeResponseTilesCount;

  /// The number of tiles that could not be downloaded because the HTTP request
  /// could not be made
  ///
  /// Where `retryFailedRequestTiles` is disabled, this is the number of
  /// [FailedRequestTileEvent]s emitted. Otherwise, this is the number of
  /// [FailedRequestTileEvent]s emitted only where
  /// [FailedRequestTileEvent.wasRetryAttempt] is `true`.
  final int failedRequestTilesCount;

  /// The number of tiles that were queued to be retried
  ///
  /// See [StoreDownload.startForeground] for more info.
  final int retryTilesQueuedCount;

  /// The total number of tiles available to be potentially downloaded and
  /// cached
  ///
  /// The difference between [DownloadableRegion.end] and
  /// [DownloadableRegion.start]. If there is no endpoint set, this is the
  /// the maximum number of tiles actually available in the region, as determined
  /// by [StoreDownload.countTiles].
  final int maxTilesCount;

  /// The current elapsed duration of the download
  ///
  /// Will be accurate to within `maxReportInterval` or better.
  final Duration elapsedDuration;

  /// The approximate/estimated number of attempted tiles per second (TPS)
  ///
  /// Note that this value is not raw. It goes through multiple layers of
  /// smoothing which takes into account more than just the previous second.
  /// It may or may not be accurate.
  final double tilesPerSecond;

  /// Whether the number of [tilesPerSecond] could be higher, but is currently
  /// capped by the set `rateLimit`
  ///
  /// This is only an approximate indicator.
  bool get isTPSArtificiallyCapped =>
      _tilesPerSecondLimit != null &&
      (tilesPerSecond >= _tilesPerSecondLimit - 0.5);

  /// The percentage [attemptedTilesCount] is of [maxTilesCount] (expressed
  /// from 0 - 100)
  double get percentageProgress => (attemptedTilesCount / maxTilesCount) * 100;

  /// The estimated total duration of the download
  ///
  /// If the [tilesPerSecond] is 0 or very small, then the reported duration
  /// is [Duration.zero].
  ///
  /// No accuracy guarantees are given. Precision to 1 second.
  ///
  /// > [!TIP]
  /// > It is not recommended to display this value directly to your user.
  /// > Instead, prefer using language such as 'about 𝑥 minutes remaining'.
  Duration get estTotalDuration => switch (tilesPerSecond) {
        < 0 => throw RangeError('Impossible `tilesPerSecond`'),
        == 0 || < 0.1 => Duration.zero,
        _ => Duration(
            seconds: max(
              elapsedDuration.inSeconds, // Prevent negative time remaining
              (maxTilesCount / tilesPerSecond).round(),
            ),
          ),
      };

  /// The estimated remaining duration of the download
  ///
  /// No accuracy guarantees are given.
  ///
  /// > [!TIP]
  /// > It is not recommended to display this value directly to your user.
  /// > Instead, prefer using language such as 'about 𝑥 minutes remaining'.
  Duration get estRemainingDuration {
    final rawRemaining = estTotalDuration - elapsedDuration;
    return rawRemaining < Duration.zero ? Duration.zero : rawRemaining;
  }

  final int? _tilesPerSecondLimit;
  final bool _retryFailedRequestTiles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadProgress &&
          successfulTilesCount == other.successfulTilesCount &&
          successfulTilesSize == other.successfulTilesSize &&
          bufferedTilesCount == other.bufferedTilesCount &&
          bufferedTilesSize == other.bufferedTilesSize &&
          seaTilesCount == other.seaTilesCount &&
          seaTilesSize == other.seaTilesSize &&
          existingTilesCount == other.existingTilesCount &&
          existingTilesSize == other.existingTilesSize &&
          negativeResponseTilesCount == other.negativeResponseTilesCount &&
          failedRequestTilesCount == other.failedRequestTilesCount &&
          retryTilesQueuedCount == other.retryTilesQueuedCount &&
          maxTilesCount == other.maxTilesCount &&
          elapsedDuration == other.elapsedDuration &&
          tilesPerSecond == other.tilesPerSecond &&
          _tilesPerSecondLimit == other._tilesPerSecondLimit);

  @override
  int get hashCode => Object.hashAllUnordered([
        successfulTilesCount,
        successfulTilesSize,
        bufferedTilesCount,
        bufferedTilesSize,
        seaTilesCount,
        seaTilesSize,
        existingTilesCount,
        existingTilesSize,
        negativeResponseTilesCount,
        failedRequestTilesCount,
        retryTilesQueuedCount,
        maxTilesCount,
        elapsedDuration,
        tilesPerSecond,
        _tilesPerSecondLimit,
      ]);
}
