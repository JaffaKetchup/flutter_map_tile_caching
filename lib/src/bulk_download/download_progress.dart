// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Represents the progress of an ongoing or finished (if [percentageProgress]
/// is 100%) bulk download
///
/// Should avoid manual construction, use named constructor
/// [DownloadProgress.empty] to generate placeholders.
class DownloadProgress {
  /// Identification number of the corresponding download
  ///
  /// A zero identification denotes that there is no corresponding download yet,
  /// usually due to the initialisation with [DownloadProgress.empty].
  final int downloadID;

  /// Class for managing the average tiles per second
  /// ([InternalProgressTimingManagement.averageTPS]) measurement of a download
  final InternalProgressTimingManagement _progressManagement;

  /// Number of tiles downloaded successfully
  ///
  /// If using buffering, it is important to note that these tiles will be
  /// written successfully (becoming part of [persistedTiles]), except in the
  /// event of a crash. In this case, the tiles that fall under the difference
  /// of [persistedTiles] - [successfulTiles] will be lost.
  ///
  /// For more information about buffering, see the
  /// [appropriate docs page](https://fmtc.jaffaketchup.dev/bulk-downloading/foreground/buffering).
  final int successfulTiles;

  /// Number of tiles persisted successfully (only significant when using
  /// buffering)
  ///
  /// This value will not necessarily change with every change to
  /// [successfulTiles]. It will only change after the buffer has been written.
  ///
  /// Tiles that fall within this number are safely persisted to the database and
  /// cannot be lost as a consequence of a crash, unlike [successfulTiles].
  ///
  /// For more information about buffering, see the
  /// [appropriate docs page](https://fmtc.jaffaketchup.dev/bulk-downloading/foreground/buffering).
  final int persistedTiles;

  /// List of URLs of failed tiles
  final List<String> failedTiles;

  /// Approximate total number of tiles to be downloaded
  final int maxTiles;

  /// Number of kibibytes successfully downloaded
  ///
  /// If using buffering, it is important to note that these tiles will be
  /// written successfully (becoming part of [persistedSize]), except in the
  /// event of a crash. In this case, the tiles that fall under the difference
  /// of [persistedSize] - [successfulSize] will be lost.
  ///
  /// For more information about buffering, see the
  /// [appropriate docs page](https://fmtc.jaffaketchup.dev/bulk-downloading/foreground/buffering).
  final double successfulSize;

  /// Number of kibibytes successfully persisted (only significant when using
  /// buffering)
  ///
  /// This value will not necessarily change with every change to
  /// [successfulSize]. It will only change after the buffer has been written.
  ///
  /// Tiles that fall within this number are safely persisted to the database and
  /// cannot be lost as a consequence of a crash, unlike [successfulSize].
  ///
  /// For more information about buffering, see the
  /// [appropriate docs page](https://fmtc.jaffaketchup.dev/bulk-downloading/foreground/buffering).
  final double persistedSize;

  /// Number of tiles removed because they were entirely sea (these also make up
  /// part of [successfulTiles])
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is
  /// always 0.
  final int seaTiles;

  /// Number of tiles not downloaded because they already existed (these also
  /// make up part of [successfulTiles])
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value
  /// is always 0.
  final int existingTiles;

  /// Elapsed duration since start of download process
  final Duration duration;

  /// Get the [ImageProvider] of the last tile that was downloaded
  ///
  /// Is `null` if the last tile failed, or the tile already existed and
  /// `preventRedownload` is enabled.
  final MemoryImage? tileImage;

  /// The [DownloadBufferMode] in use
  ///
  /// If [DownloadBufferMode.disabled], then [persistedSize] and [persistedTiles]
  /// will remain 0.
  final DownloadBufferMode bufferMode;

  /// Number of attempted tile downloads, including failure
  ///
  /// Is equal to `successfulTiles + failedTiles.length`.
  int get attemptedTiles => successfulTiles + failedTiles.length;

  /// Approximate number of tiles remaining to be downloaded
  ///
  /// Is equal to `approxMaxTiles - attemptedTiles`.
  int get remainingTiles => maxTiles - attemptedTiles;

  /// Percentage of tiles saved by using sea tile removal (ie. discount)
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is
  /// always 0.
  ///
  /// Is equal to
  /// `100 - ((((successfulTiles - existingTiles) - seaTiles) / successfulTiles) * 100)`.
  double get seaTilesDiscount => seaTiles == 0
      ? 0
      : 100 -
          ((((successfulTiles - existingTiles) - seaTiles) / successfulTiles) *
              100);

  /// Percentage of tiles saved by using redownload prevention (ie. discount)
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value
  /// is always 0.
  ///
  /// Is equal to
  /// `100 -  ((((successfulTiles - seaTiles) - existingTiles) / successfulTiles) * 100)`.
  double get existingTilesDiscount => existingTiles == 0
      ? 0
      : 100 -
          ((((successfulTiles - seaTiles) - existingTiles) / successfulTiles) *
              100);

  /// Approximate percentage of process complete
  ///
  /// Is equal to `(attemptedTiles / maxTiles) * 100`.
  double get percentageProgress => (attemptedTiles / maxTiles) * 100;

  /// Retrieve the average number of tiles per second that are being downloaded
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear
  /// average algorithm. This should lead to more accurate estimations based on
  /// this data. The full original algorithm (written in Python) can be found at
  /// https://stackoverflow.com/a/54264570/11846040.
  double get averageTPS => _progressManagement.averageTPS;

  /// Estimate duration for entire download process, using [averageTPS]
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear
  /// average algorithm. This should lead to more accurate duration calculations,
  /// but may not return the same result as expected. The full original algorithm
  /// (written in Python) can be found at
  /// https://stackoverflow.com/a/54264570/11846040.
  Duration get estTotalDuration => Duration(
        seconds: (maxTiles / averageTPS.clamp(1, double.infinity)).round(),
      );

  /// Estimate remaining duration until the end of the download process
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear
  /// average algorithm. This should lead to more accurate duration calculations,
  /// but may not return the same result as expected. The full original algorithm
  /// (written in Python) can be found at
  /// https://stackoverflow.com/a/54264570/11846040.
  Duration get estRemainingDuration => estTotalDuration - duration;

  /// Avoid construction using this method. Use [DownloadProgress.empty] to generate empty placeholders where necessary.
  DownloadProgress._({
    required this.downloadID,
    required this.successfulTiles,
    required this.persistedTiles,
    required this.failedTiles,
    required this.maxTiles,
    required this.successfulSize,
    required this.persistedSize,
    required this.seaTiles,
    required this.existingTiles,
    required this.duration,
    required this.tileImage,
    required this.bufferMode,
    required InternalProgressTimingManagement progressManagement,
  }) : _progressManagement = progressManagement;

  /// Create an empty placeholder (all values set to 0 or empty) [DownloadProgress], useful for `initialData` in a [StreamBuilder]
  DownloadProgress.empty()
      : downloadID = 0,
        successfulTiles = 0,
        persistedTiles = 0,
        failedTiles = [],
        successfulSize = 0,
        persistedSize = 0,
        maxTiles = 1,
        seaTiles = 0,
        existingTiles = 0,
        duration = Duration.zero,
        tileImage = null,
        bufferMode = DownloadBufferMode.disabled,
        _progressManagement = InternalProgressTimingManagement();

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
