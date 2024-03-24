// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';

/// Rate limiting extension, see [rateLimit] for more information
extension RateLimitedStream<E> on Stream<E> {
  /// Transforms a series of events to an output stream where a delay of at least
  /// [minimumSpacing] is inserted between every event
  ///
  /// The input stream may close before the output stream.
  ///
  /// Illustration of the output stream, where one decimal is 500ms, and
  /// [minimumSpacing] is set to 1s:
  /// ```
  ///  Input: .ABC....DE..F........GH
  /// Output: .A..B..C..D..E..F....G..H
  /// ```
  Stream<E> rateLimit({
    required Duration minimumSpacing,
    bool cancelOnError = false,
  }) {
    Completer<void> emitEvt = Completer()..complete();
    final timer = Timer.periodic(
      minimumSpacing,
      (_) {
        /// Trigger an event emission every period
        if (!emitEvt.isCompleted) emitEvt.complete();
      },
    );

    return transform<Future<E>>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(
          (() async {
            await emitEvt.future; // Await for the next signal from [timer]
            emitEvt = Completer(); // Get [timer] ready for the next signal
            return data;
          })(),
        ),
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
          if (cancelOnError) {
            timer.cancel();
            sink.close();
          }
        },
        handleDone: (sink) {
          timer.cancel();
          sink.close();
        },
      ),
    ).asyncMap((e) => e);
  }
}
