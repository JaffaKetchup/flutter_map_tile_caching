import 'package:flutter/foundation.dart';

T stopwatch<T>(T Function() time) {
  final Stopwatch stopwatch = Stopwatch()..start();
  final T r = time();
  stopwatch.stop();
  if (kDebugMode) print(stopwatch.elapsed);
  return r;
}
