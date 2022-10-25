// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';

/// Object containing the [timestamp] of the measurement and the percentage [progress] (0-1) of the applicable tile
class TimestampProgress {
  /// Time at which the measurement of progress was taken
  final DateTime timestamp;

  /// Percentage progress (0-1) of the applicable tile
  final double progress;

  /// Object containing the [timestamp] of the measurement and the percentage [progress] (0-1) of the applicable tile
  TimestampProgress(
    this.timestamp,
    this.progress,
  );

  @override
  String toString() =>
      'TileTimestampProgress(timestamp: $timestamp, progress: $progress)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimestampProgress &&
        other.timestamp == timestamp &&
        other.progress == progress;
  }

  @override
  int get hashCode => timestamp.hashCode ^ progress.hashCode;
}

/// Internal class for managing the tiles per second ([averageTPS]) measurement of a download
class InternalProgressTimingManagement {
  // ignore: cancel_subscriptions
  late StreamSubscription<void> _subscription;

  /// Map representing the progress of a tile
  ///
  /// * `key`s should be the tile identifier, created by the [Object.hashCode] method on the tile's URL to impose uniqueness
  /// * `values`s should be a [TimestampProgress], including the percentage (0-1) progress of the tile, and the timestamp the progress was taken at
  ///
  /// Should not be read outside of this object.
  final Map<int, TimestampProgress> progress = {};

  /// The number of tiles per second, based on [startTracking]
  double _averageTPS = 0;

  /// Retrieve the number of tiles per second, based on [startTracking]
  double get averageTPS => _averageTPS;

  /// Start calculating the [averageTPS] measurement
  void startTracking() {
    final List<double> tps = [];

    _subscription =
        Stream<void>.periodic(const Duration(seconds: 1)).listen((_) {
      progress.removeWhere(
        (_, v) => v.timestamp
            .isBefore(DateTime.now().subtract(const Duration(seconds: 1))),
      );
      tps.add(progress.values.map((e) => e.progress).fold(0, (p, c) => p + c));

      _averageTPS = _calculateAverage(downloadSpeeds: tps);
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
    double smoothing = 0.05,
  }) {
    if (downloadSpeeds.length == 1) return downloadSpeeds[0];

    final int samples = latestSamples == null
        ? downloadSpeeds.length
        : latestSamples.clamp(1, downloadSpeeds.length);

    return (smoothing * downloadSpeeds.last) +
        ((1 - smoothing) *
            downloadSpeeds.reversed.take(samples).reduce((v, e) => v + e) /
            samples);
  }
}
