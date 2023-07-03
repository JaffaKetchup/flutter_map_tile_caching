// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

@immutable
class DownloadProgress {
  final TileEvent? lastTileEvent;

  final int cachedTiles;
  final int prunedTiles;
  final int failedTiles;

  final int maxTiles;

  int get successfulTiles => cachedTiles + prunedTiles;
  int get attemptedTiles => successfulTiles + failedTiles;
  int get remainingTiles => maxTiles - attemptedTiles;

  final Duration duration;

  double get percentageProgress => (attemptedTiles / maxTiles) * 100;
  bool get isFinished => attemptedTiles == maxTiles;

  const DownloadProgress._({
    required this.lastTileEvent,
    required this.cachedTiles,
    required this.prunedTiles,
    required this.failedTiles,
    required this.maxTiles,
    required this.duration,
  });

  factory DownloadProgress.initial({required int maxTiles}) =>
      DownloadProgress._(
        lastTileEvent: null,
        cachedTiles: 0,
        prunedTiles: 0,
        failedTiles: 0,
        maxTiles: maxTiles,
        duration: Duration.zero,
      );

  DownloadProgress update({
    TileEvent? newTileEvent,
    required Duration newDuration,
  }) =>
      DownloadProgress._(
        lastTileEvent: newTileEvent ?? lastTileEvent,
        cachedTiles: cachedTiles +
            (newTileEvent?.result.category == TileEventResultCategory.cached
                ? 1
                : 0),
        prunedTiles: prunedTiles +
            (newTileEvent?.result.category == TileEventResultCategory.pruned
                ? 1
                : 0),
        failedTiles: failedTiles +
            (newTileEvent?.result.category == TileEventResultCategory.failed
                ? 1
                : 0),
        maxTiles: maxTiles,
        duration: newDuration,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadProgress &&
          lastTileEvent == other.lastTileEvent &&
          successfulTiles == other.successfulTiles &&
          prunedTiles == other.prunedTiles &&
          failedTiles == other.failedTiles &&
          maxTiles == other.maxTiles &&
          duration == other.duration);

  @override
  int get hashCode => Object.hashAllUnordered([
        lastTileEvent.hashCode,
        successfulTiles.hashCode,
        prunedTiles.hashCode,
        failedTiles.hashCode,
        maxTiles.hashCode,
        duration.hashCode,
      ]);
}
