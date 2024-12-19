import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class DownloadingProvider extends ChangeNotifier {
  bool _isFocused = false;
  bool get isFocused => _isFocused;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  bool _isComplete = false;
  bool get isComplete => _isComplete;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

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

  late String _storeName;

  void assignDownload({
    required String storeName,
    required DownloadableRegion downloadableRegion,
    required ({
      Stream<DownloadProgress> downloadProgress,
      Stream<TileEvent> tileEvents
    }) downloadStreams,
  }) {
    _storeName = storeName;
    _downloadableRegion = downloadableRegion;
    _isDownloading = true;

    _rawTileEventsStream = downloadStreams.tileEvents.asBroadcastStream();

    downloadStreams.downloadProgress.listen(
      (evt) {
        // Focus on initial event
        if (evt.attemptedTilesCount == 0) _isFocused = true;

        // Update stored value
        _latestDownloadProgress = evt;
        notifyListeners();
      },
      onDone: () {
        _isComplete = true;
        notifyListeners();
      },
    );

    downloadStreams.tileEvents.listen((evt) {
      // Update stored value
      _latestTileEvent = evt;
      notifyListeners();
    });
  }

  Future<void> pause() async {
    await FMTCStore(_storeName).download.pause();
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    FMTCStore(_storeName).download.resume();
    _isPaused = false;
    notifyListeners();
  }

  Future<void> cancel() => FMTCStore(_storeName).download.cancel();

  void reset() {
    _isFocused = false;
    _isComplete = false;
    _isDownloading = false;
    notifyListeners();
  }

  StateError get _notReadyError => StateError(
        'Unsafe to retrieve information before a download has been assigned.',
      );
}
