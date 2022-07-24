import 'dart:async';

/// Internal class for managing the tiles per second ([tps]) measurement of a download
class ProgressManagement {
  // ignore: cancel_subscriptions
  late StreamSubscription<void> _subscription;

  /// Map representing the percentage progress (0 - 1) of a tile, and the timestamp of each progress measurement
  ///
  /// Should not be read outside of this object.
  final Map<DateTime, double> progress = {};

  /// The number of tiles per second, based on [startTracking]
  double _tps = 0;

  /// Retrieve the number of tiles per second, based on [startTracking]
  double get tps => _tps;

  /// Internal class for managing the tiles per second ([tps]) measurement of a download
  ProgressManagement();

  /// Start calculating the [tps] measurement
  ///
  /// Increasing [pollingInterval] may increase accuracy, but will decrease the number of updates to the [tps] value.
  void startTracking({
    Duration pollingInterval = const Duration(seconds: 1),
  }) {
    final List<double> downloadSpeeds = [];

    _subscription = Stream<void>.periodic(pollingInterval).listen((_) {
      downloadSpeeds.add(
        Map<DateTime, double>.fromIterable(
          progress.keys.where(
            (k) => k.isAfter(DateTime.now().subtract(pollingInterval)),
          ),
          value: (k) => progress[k]!,
        ).values.reduce((v, e) => v + e),
      );

      _tps = _calculateTPS(
        downloadSpeeds: downloadSpeeds,
      );
    });
  }

  /// Stop calculating the [tps] measurement
  Future<void> stopTracking() => _subscription.cancel();

  /// Calculate the number of tiles that are being downloaded per second
  ///
  /// Uses an exponentially smoothed moving average algorithm instead of a linear average algorithm. This should lead to more accurate estimations based on this data. The full original algorithm (written in Python) can be found at https://stackoverflow.com/a/54264570/11846040.
  double _calculateTPS({
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
