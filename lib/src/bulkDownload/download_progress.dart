import 'package:meta/meta.dart';

/// Represents the progress of an ongoing or finished (if [percentageProgress] is 100%) bulk download
///
/// Should avoid manual construction, use named constructor `DownloadProgress.empty()` to generate placeholders.
///
/// Is yielded from `StorageCachingTileProvider().downloadRegion()`, and returned in a callback from `StorageCachingTileProvider().downloadRegionBackground()`.
class DownloadProgress {
  /// Number of successful tile downloads
  final int successfulTiles;

  /// List of URLs of failed tiles
  final List<String> failedTiles;

  /// Approximate total number of tiles to be downloaded
  final int maxTiles;

  /// Number of tiles removed because they were entirely sea (these also make up part of `successfulTiles`)
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is always 0.
  final int seaTiles;

  /// Number of tiles not downloaded because they already existed (these also make up part of `successfulTiles`)
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value is always 0.
  final int existingTiles;

  /// Duration since start of download process
  final Duration duration;

  /// Number of attempted tile downloads, including failures
  ///
  /// Is equal to `successfulTiles + failedTiles.length`.
  int get attemptedTiles => successfulTiles + failedTiles.length;

  /// Approximate number of tiles remaining to be downloaded
  ///
  /// Is equal to `approxMaxTiles - attemptedTiles`.
  int get remainingTiles => maxTiles - attemptedTiles;

  /// Percentage of tiles saved by using sea tile removal (ie. discount)
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is always 0.
  ///
  /// Is equal to `100 - ((((successfulTiles - existingTiles) - seaTiles) / successfulTiles) * 100)`.
  double get seaTilesDiscount => seaTiles == 0
      ? 0
      : 100 -
          ((((successfulTiles - existingTiles) - seaTiles) / successfulTiles) *
              100);

  /// Percentage of tiles saved by using redownload prevention (ie. discount)
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value is always 0.
  ///
  /// Is equal to `100 -  ((((successfulTiles - seaTiles) - existingTiles) / successfulTiles) * 100)`.
  double get existingTilesDiscount => existingTiles == 0
      ? 0
      : 100 -
          ((((successfulTiles - seaTiles) - existingTiles) / successfulTiles) *
              100);

  /// Approximate percentage of process complete
  ///
  /// Is equal to `(attemptedTiles / approxMaxTiles) * 100`.
  double get percentageProgress => (attemptedTiles / maxTiles) * 100;

  /// Average duration (rounded) each tile has taken to be processed
  ///
  /// Is equal to `Duration(milliseconds: (duration.inMilliseconds / attemptedTiles).round())`.
  Duration get avgDurationTile => Duration(
      milliseconds: (duration.inMilliseconds / attemptedTiles).round());

  /// Estimated duration for the whole download process based on `avgDurationTile`
  ///
  /// Is equal to `avgDurationTile * maxTiles`.
  Duration get estTotalDuration => avgDurationTile * maxTiles;

  /// Estimated remaining duration until the end of the download process, based on `estTotalDuration`
  ///
  /// Is equal to `estTotalDuration - duration`
  Duration get estRemainingDuration => estTotalDuration - duration;

  /// Deprecated due to internal refactoring. Migrate to `attemptedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.
  @Deprecated(
      'Deprecated due to internal refactoring. Migrate to `attemptedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.')
  int get completedTiles => attemptedTiles;

  /// Deprecated due to internal refactoring. Migrate to `failedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.
  @Deprecated(
      'Due to internal refactoring. Migrate to `failedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.')
  List<String> get erroredTiles => failedTiles;

  /// Deprecated due to internal refactoring. Migrate to `maxTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.
  @Deprecated(
      'Due to internal refactoring. Migrate to `maxTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.')
  int get totalTiles => maxTiles;

  /// Avoid construction using this method. Use [DownloadProgress.empty] to generate empty placeholders where necessary.
  @internal
  DownloadProgress.internal({
    required this.successfulTiles,
    required this.failedTiles,
    required this.maxTiles,
    required this.seaTiles,
    required this.existingTiles,
    required this.duration,
  });

  /// Create an empty placeholder (all values set to 0 or empty) [DownloadProgress], useful for `initalData` in a [StreamBuilder]
  DownloadProgress.empty()
      : successfulTiles = 0,
        failedTiles = [],
        maxTiles = 0,
        seaTiles = 0,
        existingTiles = 0,
        duration = const Duration(seconds: 0);

  /// Deprecated due to internal refactoring. Migrate to the named constructor [DownloadProgress.empty]. Will be removed in next update.
  @Deprecated(
      'Due to internal refactoring. Migrate to the named constructor [DownloadProgress.empty]. Will be removed in next update.')
  static DownloadProgress get placeholder => DownloadProgress.empty();
}
