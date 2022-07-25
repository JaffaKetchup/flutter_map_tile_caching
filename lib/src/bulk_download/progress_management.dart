import 'dart:async';

class TileTimestampProgress {
  final int? tileID;
  final DateTime? timestamp;
  final double progress;

  TileTimestampProgress(
    String? tileURL,
    this.timestamp,
    this.progress,
  ) : tileID = tileURL?.hashCode;

  @override
  String toString() =>
      'TileTimestampProgress(tileID: $tileID, timestamp: $timestamp, progress: $progress)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TileTimestampProgress &&
        other.tileID == tileID &&
        other.timestamp == timestamp &&
        other.progress == progress;
  }

  @override
  int get hashCode => tileID.hashCode ^ timestamp.hashCode ^ progress.hashCode;
}

/// Internal class for managing the tiles per second ([averageTPS]) measurement of a download
class ProgressManagement {
  // ignore: cancel_subscriptions
  late StreamSubscription<void> _subscription;

  /// Map representing the progress of a tile
  ///
  /// * `key`s should be the tile identifier, created by the [Object.hashCode] method on the tile's URL.
  /// * `values`s should be a [TileTimestampProgress], including the percentage (0-1) progress of the tile, and the timestamp the progress was taken at.
  ///
  /// Should not be read outside of this object.
  final List<TileTimestampProgress> progress = [];

  /// The number of tiles per second, based on [startTracking]
  double _averageTPS = 0;

  /// Retrieve the number of tiles per second, based on [startTracking]
  double get averageTPS => _averageTPS;

  /// Internal class for managing the tiles per second ([averageTPS]) measurement of a download
  ProgressManagement();

  /// Start calculating the [averageTPS] measurement
  ///
  /// Increasing [pollingInterval] may increase accuracy, but will decrease the number of updates to the [averageTPS] value.
  Future<void> startTracking({
    Duration pollingInterval = const Duration(milliseconds: 100),
  }) async {
    final List<double> downloadSpeeds = [];

    _subscription = Stream<void>.periodic(pollingInterval).listen((_) {
      final Iterable<TileTimestampProgress> filtered = progress.where(
        (e) => e.timestamp!.isAfter(DateTime.now().subtract(pollingInterval)),
      );

      downloadSpeeds.add(
        (filtered.isEmpty ? [TileTimestampProgress(null, null, 0)] : filtered)
            .toList()
            .reduce(
              (v, e) => TileTimestampProgress(
                null,
                null,
                v.progress + e.progress,
              ),
            )
            .progress,
      );

      _averageTPS = (_calculateAverage(
                downloadSpeeds: downloadSpeeds,
              ) *
              (1000 / pollingInterval.inMilliseconds)) /
          progress
              .where((e) => e.progress == 1)
              .length
              .clamp(1, double.infinity);
    });
  }

  /// Stop calculating the [averageTPS] measurement
  Future<void> stopTracking() => _subscription.cancel();

  /// Calculate the number of tiles that are being downloaded per second on average
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear average algorithm. This should lead to more accurate estimations based on this data. The full original algorithm (written in Python) can be found at https://stackoverflow.com/a/54264570/11846040.
  double _calculateAverage({
    required List<double> downloadSpeeds,
    int? latestSamples,
    double smoothing = 0.02,
  }) {
    if (downloadSpeeds.length == 1) return downloadSpeeds[0];

    final int samples = latestSamples == null
        ? downloadSpeeds.length
        : latestSamples.clamp(1, downloadSpeeds.length);

    return (smoothing * downloadSpeeds.last) +
        ((1 - smoothing) *
            downloadSpeeds.reversed
                .take(samples)
                .toList()
                .reduce((v, e) => v + e) /
            samples);
  }
}
