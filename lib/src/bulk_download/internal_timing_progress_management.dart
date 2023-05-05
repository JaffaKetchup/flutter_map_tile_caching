// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';

import 'package:collection/collection.dart';

/// Object containing the [timestamp] of the measurement and the percentage
/// [progress] (0-1) of the applicable tile
class TimestampProgress {
  /// Time at which the measurement of progress was taken
  final DateTime timestamp;

  /// Percentage progress (0-1) of the applicable tile
  final double progress;

  /// Object containing the [timestamp] of the measurement and the percentage
  /// [progress] (0-1) of the applicable tile
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

/// Internal class for managing the tiles per second ([averageTPS]) measurement
/// of a download
class InternalProgressTimingManagement {
  static const double _smoothing = 0.05;

  late Timer _timer;
  final List<double> _tpsMeasurements = [];
  final Map<String, TimestampProgress> _rawProgresses = {};
  double _averageTPS = 0;

  /// Retrieve the number of tiles per second
  ///
  /// Always 0 if [start] has not been called or [stop] has been called
  double get averageTPS => _averageTPS;

  /// Calculate the number of tiles that are being downloaded per second on
  /// average, and write to [averageTPS]
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear
  /// average algorithm. This should lead to more accurate estimations based on
  /// this data. The full original algorithm (written in Python) can be found at
  /// https://stackoverflow.com/a/54264570/11846040.
  void start() => _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _rawProgresses.removeWhere(
          (_, v) => v.timestamp
              .isBefore(DateTime.now().subtract(const Duration(seconds: 1))),
        );
        _tpsMeasurements.add(_rawProgresses.values.map((e) => e.progress).sum);

        _averageTPS = _tpsMeasurements.length == 1
            ? _tpsMeasurements[0]
            : (_smoothing * _tpsMeasurements.last) +
                ((1 - _smoothing) *
                    _tpsMeasurements.sum /
                    _tpsMeasurements.length);
      });

  /// Stop calculating the [averageTPS] measurement
  void stop() {
    _timer.cancel();
    _averageTPS = 0;
  }

  /// Insert a new tile progress event into [_rawProgresses], to be accounted for
  /// by [averageTPS]
  void registerEvent(String url, TimestampProgress progress) =>
      _rawProgresses[url] = progress;
}
