import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Represents the progress of an ongoing or finished (if [percentageProgress] is 100%) bulk download
///
/// Should avoid manual construction, use named constructor [DownloadProgress.empty] to generate placeholders.
///
/// Is yielded from `StorageCachingTileProvider().downloadRegion()`, and returned in a callback from `StorageCachingTileProvider().downloadRegionBackground()`.
class DownloadProgress {
  /// Number of successful tile downloads
  final int successfulTiles;

  /// List of URLs of failed tiles
  final List<String> failedTiles;

  /// Approximate total number of tiles to be downloaded
  final int maxTiles;

  /// Number of tiles removed because they were entirely sea (these also make up part of [successfulTiles])
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is always 0.
  final int seaTiles;

  /// Number of tiles not downloaded because they already existed (these also make up part of [successfulTiles])
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value is always 0.
  final int existingTiles;

  /// The length of time each tile took to download (one element per tile)
  ///
  /// Use [duration] for time elapsed so far (each element added up)
  final List<Duration> durationPerTile;

  /// Elapsed duration since start of download process
  final Duration duration;

  /// Number of attempted tile downloads, including failures
  ///
  /// Note that this is not used in any other calculations: for example, [remainingTiles] uses [successfulTiles] instead of this.
  ///
  /// Is equal to `successfulTiles + failedTiles.length`.
  int get attemptedTiles => successfulTiles + failedTiles.length;

  /// Approximate number of tiles remaining to be downloaded
  ///
  /// Is equal to `approxMaxTiles - successfulTiles`.
  int get remainingTiles => maxTiles - successfulTiles;

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

  /// Estimated duration for entire download process, based on existing progress and elapsed duration
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear average algorithm. This should lead to more accurate duration calculations, but may not return the same result as expected. The full original algorithm (written in Python) can be found at https://stackoverflow.com/a/54264570/11846040.
  Duration get estTotalDuration {
    final List<int> data =
        durationPerTile.map((e) => e.inMicroseconds).toList();
    const double smoothing = 0.005;

    return Duration(
          microseconds: data.length == 1
              ? data[0]
              : ((smoothing * data.last) +
                      ((1 - smoothing) * (data.sum / data.length)))
                  .round(),
        ) *
        (maxTiles / 2);
  }

  /// Estimated remaining duration until the end of the download process, based on [estTotalDuration]
  ///
  /// Is equal to `estTotalDuration - duration`
  Duration get estRemainingDuration => estTotalDuration - duration;

  /// Avoid construction using this method. Use [DownloadProgress.empty] to generate empty placeholders where necessary.
  @internal
  DownloadProgress.internal({
    required this.successfulTiles,
    required this.failedTiles,
    required this.maxTiles,
    required this.seaTiles,
    required this.existingTiles,
    required this.durationPerTile,
    required this.duration,
  });

  /// Create an empty placeholder (all values set to 0 or empty) [DownloadProgress], useful for `initalData` in a [StreamBuilder]
  DownloadProgress.empty()
      : successfulTiles = 0,
        failedTiles = [],
        maxTiles = 0,
        seaTiles = 0,
        existingTiles = 0,
        durationPerTile = [],
        duration = Duration.zero;

  //! GENERAL OBJECT STUFF !//

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadProgress &&
        other.successfulTiles == successfulTiles &&
        other.failedTiles == failedTiles &&
        other.maxTiles == maxTiles &&
        other.seaTiles == seaTiles &&
        other.existingTiles == existingTiles &&
        other.duration == duration;
  }

  @override
  int get hashCode =>
      successfulTiles.hashCode ^
      failedTiles.hashCode ^
      maxTiles.hashCode ^
      seaTiles.hashCode ^
      existingTiles.hashCode ^
      duration.hashCode;
}
