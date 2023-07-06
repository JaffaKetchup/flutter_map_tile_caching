// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

@immutable
class DownloadProgress {
  /// The result of the last attempted tile
  ///
  /// May be used for UI display, error handling, or debugging purposes.
  TileEvent get lastTileEvent => _lastTileEvent!;
  final TileEvent? _lastTileEvent;

  /// The number of new tiles successfully downloaded and cached, that is those
  /// tiles with the result of [TileEventResult.success]
  /// ([TileEventResultCategory.cached])
  final int cachedTiles;
  final double cachedSize;
  final int bufferedTiles;
  final double bufferedSize;
  final int skippedTiles;
  final double skippedSize;
  final int failedTiles;
  final int maxTiles;

  final Duration elapsedDuration;
  final double tilesPerSecond;
  final bool isTPSArtificiallyCapped;

  final bool isComplete;

  int get successfulTiles => cachedTiles + skippedTiles;
  double get successfulSize => cachedSize + skippedSize;
  int get attemptedTiles => successfulTiles + failedTiles;
  int get remainingTiles => maxTiles - attemptedTiles;

  double get percentageProgress => (attemptedTiles / maxTiles) * 100;

  Duration get estTotalDuration => isComplete
      ? elapsedDuration
      : Duration(
          seconds:
              (((maxTiles / tilesPerSecond.clamp(1, largestInt)) / 10).round() *
                      10)
                  .clamp(elapsedDuration.inSeconds, largestInt),
        );
  Duration get estRemainingDuration =>
      estTotalDuration - elapsedDuration < Duration.zero
          ? Duration.zero
          : estTotalDuration - elapsedDuration;

  const DownloadProgress.__({
    required TileEvent? lastTileEvent,
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
  }) : _lastTileEvent = lastTileEvent;

  factory DownloadProgress._initial({required int maxTiles}) =>
      DownloadProgress.__(
        lastTileEvent: null,
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

  DownloadProgress _updateProgress({
    required Duration newDuration,
    required double tilesPerSecond,
    required int? rateLimit,
  }) =>
      DownloadProgress.__(
        lastTileEvent: lastTileEvent,
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
        lastTileEvent: newTileEvent ?? lastTileEvent,
        cachedTiles: newTileEvent == null
            ? cachedTiles
            : newTileEvent.result.category == TileEventResultCategory.cached
                ? cachedTiles + 1
                : cachedTiles,
        cachedSize: newTileEvent == null
            ? cachedSize
            : newTileEvent.result.category == TileEventResultCategory.cached
                ? cachedSize + (newTileEvent.tileImage!.lengthInBytes / 1024)
                : cachedSize,
        bufferedTiles: newBufferedTiles,
        bufferedSize: newBufferedSize,
        skippedTiles: newTileEvent == null
            ? skippedTiles
            : newTileEvent.result.category == TileEventResultCategory.skipped
                ? skippedTiles + 1
                : skippedTiles,
        skippedSize: newTileEvent == null
            ? skippedSize
            : newTileEvent.result.category == TileEventResultCategory.skipped
                ? skippedSize + (newTileEvent.tileImage!.lengthInBytes / 1024)
                : skippedSize,
        failedTiles: newTileEvent == null
            ? failedTiles
            : newTileEvent.result.category == TileEventResultCategory.failed
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
          _lastTileEvent == other._lastTileEvent &&
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
        _lastTileEvent,
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
