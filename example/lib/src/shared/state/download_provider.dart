import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class DownloadingProvider extends ChangeNotifier {
  bool _isFocused = false;
  bool get isFocused => _isFocused;

  bool get isPaused => FMTCStore(storeName!).download.isPaused();

  bool _isComplete = false;
  bool get isComplete => _isComplete;

  DownloadableRegion? _downloadableRegion;
  DownloadableRegion get downloadableRegion =>
      _downloadableRegion ?? (throw _notReadyError);

  DownloadProgress? _latestDownloadProgress;
  DownloadProgress get latestDownloadProgress =>
      _latestDownloadProgress ?? (throw _notReadyError);

  TileEvent? _latestTileEvent;
  TileEvent? get latestTileEvent => _latestTileEvent;

  Stream<TileEvent>? _rawTileEventsStream;
  Stream<TileEvent> get rawTileEventStream =>
      _rawTileEventsStream ?? (throw _notReadyError);

  String? _storeName;
  String? get storeName => _storeName;

  Future<void> assignDownload({
    required String storeName,
    required DownloadableRegion downloadableRegion,
    required ({
      Stream<DownloadProgress> downloadProgress,
      Stream<TileEvent> tileEvents
    }) downloadStreams,
  }) {
    final focused = Completer<void>();

    _storeName = storeName;
    _downloadableRegion = downloadableRegion;

    _rawTileEventsStream = downloadStreams.tileEvents.asBroadcastStream();

    bool isFirstEvent = true;
    downloadStreams.downloadProgress.listen(
      (evt) {
        // Focus on initial event
        if (isFirstEvent) {
          _isFocused = true;
          focused.complete();
          isFirstEvent = false;
        }

        // Update stored value
        _latestDownloadProgress = evt;
        notifyListeners();
      },
      onDone: () {
        _isComplete = true;
        notifyListeners();
      },
    );

    _rawTileEventsStream!.listen((evt) {
      // Update stored value
      _latestTileEvent = evt;
      notifyListeners();
    });

    return focused.future;
  }

  Future<void> pause() async {
    assert(_storeName != null, 'Download not in progress');
    await FMTCStore(_storeName!).download.pause();
    notifyListeners();
  }

  void resume() {
    assert(_storeName != null, 'Download not in progress');
    FMTCStore(_storeName!).download.resume();
    notifyListeners();
  }

  Future<void> cancel() {
    assert(_storeName != null, 'Download not in progress');
    return FMTCStore(_storeName!).download.cancel();
  }

  void reset() {
    _isFocused = false;
    _isComplete = false;
    _storeName = null;
    _downloadableRegion = null;
    notifyListeners();
  }

  StateError get _notReadyError => StateError(
        'Unsafe to retrieve information before a download has been assigned.',
      );

  bool _useMaskEffect = true;
  bool get useMaskEffect => _useMaskEffect;
  set useMaskEffect(bool newState) {
    _useMaskEffect = newState;
    notifyListeners();
  }
}
