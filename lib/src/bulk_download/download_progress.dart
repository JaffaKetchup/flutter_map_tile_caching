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
  final int prunedTiles;
  final double prunedSize;
  final int failedTiles;
  final int maxTiles;
  final Duration duration;
  final bool hasFinished;

  int get successfulTiles => cachedTiles + prunedTiles;
  double get successfulSize => cachedSize + prunedSize;
  int get attemptedTiles => successfulTiles + failedTiles;
  int get remainingTiles => maxTiles - attemptedTiles;

  double get percentageProgress => (attemptedTiles / maxTiles) * 100;

  const DownloadProgress.__({
    required TileEvent? lastTileEvent,
    required this.cachedTiles,
    required this.cachedSize,
    required this.bufferedTiles,
    required this.bufferedSize,
    required this.prunedTiles,
    required this.prunedSize,
    required this.failedTiles,
    required this.maxTiles,
    required this.duration,
    required this.hasFinished,
  }) : _lastTileEvent = lastTileEvent;

  factory DownloadProgress._initial({required int maxTiles}) =>
      DownloadProgress.__(
        lastTileEvent: null,
        cachedTiles: 0,
        cachedSize: 0,
        bufferedTiles: 0,
        bufferedSize: 0,
        prunedTiles: 0,
        prunedSize: 0,
        failedTiles: 0,
        maxTiles: maxTiles,
        duration: Duration.zero,
        hasFinished: false,
      );

  DownloadProgress _updateDuration(
    Duration newDuration,
  ) =>
      DownloadProgress.__(
        lastTileEvent: lastTileEvent,
        cachedTiles: cachedTiles,
        cachedSize: cachedSize,
        bufferedTiles: bufferedTiles,
        bufferedSize: bufferedSize,
        prunedTiles: prunedTiles,
        prunedSize: prunedSize,
        failedTiles: failedTiles,
        maxTiles: maxTiles,
        duration: newDuration,
        hasFinished: false,
      );

  DownloadProgress _update({
    required TileEvent? newTileEvent,
    required int newBufferedTiles,
    required double newBufferedSize,
    required Duration newDuration,
    bool hasFinished = false,
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
        prunedTiles: newTileEvent == null
            ? prunedTiles
            : newTileEvent.result.category == TileEventResultCategory.pruned
                ? prunedTiles + 1
                : prunedTiles,
        prunedSize: newTileEvent == null
            ? prunedSize
            : newTileEvent.result.category == TileEventResultCategory.pruned
                ? prunedSize + (newTileEvent.tileImage!.lengthInBytes / 1024)
                : prunedSize,
        failedTiles: newTileEvent == null
            ? failedTiles
            : newTileEvent.result.category == TileEventResultCategory.failed
                ? failedTiles + 1
                : failedTiles,
        maxTiles: maxTiles,
        duration: newDuration,
        hasFinished: hasFinished,
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
          prunedTiles == other.prunedTiles &&
          prunedSize == other.prunedSize &&
          failedTiles == other.failedTiles &&
          maxTiles == other.maxTiles &&
          duration == other.duration &&
          hasFinished == other.hasFinished);

  @override
  int get hashCode => Object.hashAllUnordered([
        _lastTileEvent.hashCode,
        cachedTiles.hashCode,
        cachedSize.hashCode,
        bufferedTiles.hashCode,
        bufferedSize.hashCode,
        prunedTiles.hashCode,
        prunedSize.hashCode,
        failedTiles.hashCode,
        maxTiles.hashCode,
        duration.hashCode,
        hasFinished.hashCode,
      ]);
}
