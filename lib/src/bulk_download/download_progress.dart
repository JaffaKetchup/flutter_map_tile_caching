// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Statistics and information about the current progress of the download
///
/// Note that there a number of things to keep in mind when tracking the progress
/// of a download. See https://fmtc.jaffaketchup.dev/bulk-downloading/foreground
/// for more information.
///
/// See the documentation on each individual property for more information.
@immutable
class DownloadProgress {
  const DownloadProgress.__({
    required TileEvent? latestTileEvent,
    required this.cachedTiles,
    required this.cachedSize,
    required this.bufferedTiles,
    required this.bufferedSize,
    required this.skippedTiles,
    required this.skippedSize,
    required this.failedTiles,
    required this.maxTiles,
    required this.elapsedDuration,
    required this.tilesPerSecond,
    required this.isTPSArtificiallyCapped,
    required this.isComplete,
  }) : _latestTileEvent = latestTileEvent;

  factory DownloadProgress._initial({required int maxTiles}) =>
      DownloadProgress.__(
        latestTileEvent: null,
        cachedTiles: 0,
        cachedSize: 0,
        bufferedTiles: 0,
        bufferedSize: 0,
        skippedTiles: 0,
        skippedSize: 0,
        failedTiles: 0,
        maxTiles: maxTiles,
        elapsedDuration: Duration.zero,
        tilesPerSecond: 0,
        isTPSArtificiallyCapped: false,
        isComplete: false,
      );

  /// The result of the latest attempted tile
  ///
  /// Note that there a number of things to keep in mind when tracking the
  /// progress of a download. See
  /// https://fmtc.jaffaketchup.dev/bulk-downloading/foreground for more
  /// information.
  TileEvent get latestTileEvent => _latestTileEvent!;
  final TileEvent? _latestTileEvent;

  /// The number of new tiles successfully downloaded and in the tile buffer or
  /// cached
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.cached].
  ///
  /// Includes [bufferedTiles].
  final int cachedTiles;

  /// The total size (in KiB) of new tiles successfully downloaded and in the
  /// tile buffer or cached
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.cached].
  ///
  /// Includes [bufferedSize].
  final double cachedSize;

  /// The number of new tiles successfully downloaded and in the tile buffer
  /// waiting to be cached
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.cached].
  ///
  /// Part of [cachedTiles].
  final int bufferedTiles;

  /// The total size (in KiB) of new tiles successfully downloaded and in the
  /// tile buffer waiting to be cached
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.cached].
  ///
  /// Part of [cachedSize].
  final double bufferedSize;

  /// The number of tiles that were skipped (not cached) because they either:
  ///  - already existed & `skipExistingTiles` was `true`
  ///  - were a sea tile & `skipSeaTiles` was `true`
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.skipped].
  final int skippedTiles;

  /// The total size (in KiB) of tiles that were skipped (not cached) because
  /// they either:
  ///  - already existed & `skipExistingTiles` was `true`
  ///  - were a sea tile & `skipSeaTiles` was `true`
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.skipped].
  final double skippedSize;

  /// The number of tiles that were not successfully downloaded, potentially for
  /// a variety of reasons
  ///
  /// [TileEvent]s with the result category of [TileEventResultCategory.failed].
  ///
  /// To check why these tiles failed, use [latestTileEvent] to construct a list
  /// of tiles that failed.
  final int failedTiles;

  /// The total number of tiles available to be potentially downloaded and
  /// cached
  final int maxTiles;

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
  final bool isTPSArtificiallyCapped;

  /// Whether the download is now complete
  ///
  /// There will be no more events after this event, regardless of other
  /// statistics.
  ///
  /// Prefer using this over checking any other statistics for completion. If all
  /// threads have unexpectedly quit due to an error, the other statistics will
  /// not indicate the the download has stopped/finished/completed, but this will
  /// be `true`.
  final bool isComplete;

  /// The number of tiles that were either cached, in buffer, or skipped
  ///
  /// Equal to [cachedTiles] + [skippedTiles].
  int get successfulTiles => cachedTiles + skippedTiles;

  /// The total size (in KiB) of tiles that were either cached, in buffer, or
  /// skipped
  ///
  /// Equal to [cachedSize] + [skippedSize].
  double get successfulSize => cachedSize + skippedSize;

  /// The number of tiles that have been attempted, with any result
  ///
  /// Equal to [successfulTiles] + [failedTiles].
  int get attemptedTiles => successfulTiles + failedTiles;

  /// The number of tiles that have not yet been attempted
  ///
  /// Equal to [maxTiles] - [attemptedTiles].
  int get remainingTiles => maxTiles - attemptedTiles;

  /// The number of attempted tiles over the number of available tiles as a
  /// percentage
  ///
  /// Equal to [attemptedTiles] / [maxTiles] multiplied by 100.
  double get percentageProgress => (attemptedTiles / maxTiles) * 100;

  /// The estimated total duration of the download
  ///
  /// It may or may not be accurate, except when [isComplete] is `true`, in which
  /// event, this will always equal [elapsedDuration].
  ///
  /// It is not recommended to display this value directly to your user. Instead,
  /// prefer using language such as 'about 𝑥 minutes remaining'.
  Duration get estTotalDuration => isComplete
      ? elapsedDuration
      : Duration(
          seconds:
              (((maxTiles / tilesPerSecond.clamp(1, largestInt)) / 10).round() *
                      10)
                  .clamp(elapsedDuration.inSeconds, largestInt),
        );

  /// The estimated remaining duration of the download.
  ///
  /// It may or may not be accurate.
  ///
  /// It is not recommended to display this value directly to your user. Instead,
  /// prefer using language such as 'about 𝑥 minutes remaining'.
  Duration get estRemainingDuration =>
      estTotalDuration - elapsedDuration < Duration.zero
          ? Duration.zero
          : estTotalDuration - elapsedDuration;

  DownloadProgress _fallbackReportUpdate({
    required Duration newDuration,
    required double tilesPerSecond,
    required int? rateLimit,
  }) =>
      DownloadProgress.__(
        latestTileEvent: latestTileEvent._repeat(),
        cachedTiles: cachedTiles,
        cachedSize: cachedSize,
        bufferedTiles: bufferedTiles,
        bufferedSize: bufferedSize,
        skippedTiles: skippedTiles,
        skippedSize: skippedSize,
        failedTiles: failedTiles,
        maxTiles: maxTiles,
        elapsedDuration: newDuration,
        tilesPerSecond: tilesPerSecond,
        isTPSArtificiallyCapped:
            tilesPerSecond >= (rateLimit ?? double.infinity) - 0.5,
        isComplete: false,
      );

  DownloadProgress _updateProgressWithTile({
    required TileEvent? newTileEvent,
    required int newBufferedTiles,
    required double newBufferedSize,
    required Duration newDuration,
    required double tilesPerSecond,
    required int? rateLimit,
    bool isComplete = false,
  }) =>
      DownloadProgress.__(
        latestTileEvent: newTileEvent ?? latestTileEvent,
        cachedTiles: newTileEvent != null &&
                newTileEvent.result.category == TileEventResultCategory.cached
            ? cachedTiles + 1
            : cachedTiles,
        cachedSize: newTileEvent != null &&
                newTileEvent.result.category == TileEventResultCategory.cached
            ? cachedSize + (newTileEvent.tileImage!.lengthInBytes / 1024)
            : cachedSize,
        bufferedTiles: newBufferedTiles,
        bufferedSize: newBufferedSize,
        skippedTiles: newTileEvent != null &&
                newTileEvent.result.category == TileEventResultCategory.skipped
            ? skippedTiles + 1
            : skippedTiles,
        skippedSize: newTileEvent != null &&
                newTileEvent.result.category == TileEventResultCategory.skipped
            ? skippedSize + (newTileEvent.tileImage!.lengthInBytes / 1024)
            : skippedSize,
        failedTiles: newTileEvent != null &&
                newTileEvent.result.category == TileEventResultCategory.failed
            ? failedTiles + 1
            : failedTiles,
        maxTiles: maxTiles,
        elapsedDuration: newDuration,
        tilesPerSecond: tilesPerSecond,
        isTPSArtificiallyCapped:
            tilesPerSecond >= (rateLimit ?? double.infinity) - 0.5,
        isComplete: isComplete,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadProgress &&
          _latestTileEvent == other._latestTileEvent &&
          cachedTiles == other.cachedTiles &&
          cachedSize == other.cachedSize &&
          bufferedTiles == other.bufferedTiles &&
          bufferedSize == other.bufferedSize &&
          skippedTiles == other.skippedTiles &&
          skippedSize == other.skippedSize &&
          failedTiles == other.failedTiles &&
          maxTiles == other.maxTiles &&
          elapsedDuration == other.elapsedDuration &&
          tilesPerSecond == other.tilesPerSecond &&
          isTPSArtificiallyCapped == other.isTPSArtificiallyCapped &&
          isComplete == other.isComplete);

  @override
  int get hashCode => Object.hashAllUnordered([
        _latestTileEvent,
        cachedTiles,
        cachedSize,
        bufferedTiles,
        bufferedSize,
        skippedTiles,
        skippedSize,
        failedTiles,
        maxTiles,
        elapsedDuration,
        tilesPerSecond,
        isTPSArtificiallyCapped,
        isComplete,
      ]);
}
