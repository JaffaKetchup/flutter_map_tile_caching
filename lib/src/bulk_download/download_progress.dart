import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'progress_management.dart';

/// Represents the progress of an ongoing or finished (if [percentageProgress] is 100%) bulk download
///
/// Should avoid manual construction, use named constructor [DownloadProgress.empty] to generate placeholders.
class DownloadProgress {
  /// Identification number of the corresponding download
  ///
  /// A zero identification denotes that there is no corresponding download yet, usually due to the initialisation with [DownloadProgress.empty].
  final int downloadID;

  /// Class for managing the tiles per second ([ProgressManagement.averageTPS]) measurement of a download
  final ProgressManagement _progressManagement;

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

  /// Elapsed duration since start of download process
  final Duration duration;

  /// Get the [ImageProvider] of the last tile that was downloaded
  ///
  /// Is `null` if the last tile failed, or the tile already existed and `preventRedownload` is enabled.
  MemoryImage? tileImage;

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

  /// Calculate the number of tiles that are being downloaded per second
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear average algorithm. This should lead to more accurate estimations based on this data. The full original algorithm (written in Python) can be found at https://stackoverflow.com/a/54264570/11846040.
  double get tilesPerSecond => _progressManagement.averageTPS;

  /// Estimate duration for entire download process
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear average algorithm. This should lead to more accurate duration calculations, but may not return the same result as expected. The full original algorithm (written in Python) can be found at https://stackoverflow.com/a/54264570/11846040.
  Duration get estTotalDuration => Duration(
        seconds: (maxTiles / tilesPerSecond.clamp(1, double.infinity)).round(),
      );

  /// Estimated remaining duration until the end of the download process, based on [estTotalDuration]
  ///
  /// Is equal to `estTotalDuration - duration`
  Duration get estRemainingDuration => estTotalDuration - duration;

  /// Avoid construction using this method. Use [DownloadProgress.empty] to generate empty placeholders where necessary.
  @internal
  DownloadProgress.internal({
    required this.downloadID,
    required this.successfulTiles,
    required this.failedTiles,
    required this.maxTiles,
    required this.seaTiles,
    required this.existingTiles,
    required this.duration,
    required this.tileImage,
    required ProgressManagement progressManagement,
  }) : _progressManagement = progressManagement;

  /// Create an empty placeholder (all values set to 0 or empty) [DownloadProgress], useful for `initalData` in a [StreamBuilder]
  DownloadProgress.empty()
      : downloadID = 0,
        successfulTiles = 0,
        failedTiles = [],
        maxTiles = 1,
        seaTiles = 0,
        existingTiles = 0,
        duration = Duration.zero,
        _progressManagement = ProgressManagement();

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
