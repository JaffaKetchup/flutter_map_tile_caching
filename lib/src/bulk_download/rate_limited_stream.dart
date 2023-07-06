// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';

/// Transforms a series of events to an output [stream] where a delay of at least
/// [emitEvery] is inserted between every event
///
/// There are 3 ways to contruct this:
///  - [RateLimitedStream] : No initial stream, remains open until [close] called
///  - [RateLimitedStream.withInitialStream] : Uses initial stream, remains open
/// until [close] called
///  - [RateLimitedStream.fromSourceStream] : One-shot from source stream, closes
/// automatically after output completes
///
/// Remember, input streams are likely to close before the output [stream].
///
/// Do not call [close] if input streams are still outputting or new events are
/// being [add]ed.
///
/// Optionally pass in a `customStreamController`. If passed in, use only this
/// object's methods to manipulate the stream, not the passed in controller's
/// methods.
///
/// Illustration of [stream], where one decimal is 500ms, and [emitEvery] is set
/// to 1s:
/// ```
///  Input: .ABC....DE..F........GH
/// Output: .A..B..C..D..E..F....G..H
/// ```
class RateLimitedStream<E> {
  RateLimitedStream({
    required this.emitEvery,
    this.cancelOnError = false,
    StreamController<E>? customStreamController,
  }) : _streamController = customStreamController ?? StreamController();

  RateLimitedStream.withInitialStream({
    required this.emitEvery,
    required Stream<E> initialStream,
    this.cancelOnError = false,
    StreamController<E>? customStreamController,
  }) : _streamController = customStreamController ?? StreamController() {
    _streamController.addStream(initialStream, cancelOnError: cancelOnError);
  }

  RateLimitedStream.fromSourceStream({
    required this.emitEvery,
    required Stream<E> sourceStream,
    this.cancelOnError = false,
    StreamController<E>? customStreamController,
  }) : _streamController = customStreamController ?? StreamController() {
    _streamController
        .addStream(sourceStream, cancelOnError: cancelOnError)
        .then((_) => close());
  }

  final Duration emitEvery;
  final bool cancelOnError;

  final StreamController<E> _streamController;

  void add(E event) => _streamController.sink.add(event);
  Future<dynamic> addStream(Stream<E> stream) =>
      _streamController.sink.addStream(stream);
  void addError(Object error, [StackTrace? stackTrace]) =>
      _streamController.sink.addError(error, stackTrace);
  Future<dynamic> close() => _streamController.sink.close();
  Future<dynamic> get done => _streamController.sink.done;

  Stream<E> get stream {
    Completer<void> emitEvt = Completer()..complete();
    Timer.periodic(emitEvery, (_) {
      if (!emitEvt.isCompleted) emitEvt.complete();
    });

    return _streamController.stream
        .transform<Future<E>>(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(
              (() async {
                await emitEvt.future;
                emitEvt = Completer();
                return data;
              })(),
            ),
            handleError: (error, stackTrace, sink) {
              sink.addError(error, stackTrace);
              if (cancelOnError) sink.close();
            },
            handleDone: (sink) => sink.close(),
          ),
        )
        .asyncMap((e) => e);
  }
}
