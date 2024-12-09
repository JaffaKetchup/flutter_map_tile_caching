import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class DownloadingProvider extends ChangeNotifier {
  bool _isFocused = false;
  bool get isFocused => _isFocused;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  DownloadableRegion? _downloadableRegion;
  DownloadableRegion get downloadableRegion =>
      _downloadableRegion ?? (throw _notReadyError);

  DownloadProgress? _latestEvent;
  DownloadProgress get latestEvent => _latestEvent ?? (throw _notReadyError);

  Stream<DownloadProgress>? _rawStream;
  Stream<DownloadProgress> get rawStream =>
      _rawStream ?? (throw _notReadyError);

  late int _skippedSeaTileCount;
  int get skippedSeaTileCount => _skippedSeaTileCount;

  late int _skippedSeaTileSize;
  int get skippedSeaTileSize => _skippedSeaTileSize;

  late int _skippedExistingTileCount;
  int get skippedExistingTileCount => _skippedExistingTileCount;

  late int _skippedExistingTileSize;
  int get skippedExistingTileSize => _skippedExistingTileSize;

  late String _storeName;
  late StreamSubscription<DownloadProgress> _streamSub;

  void assignDownload({
    required String storeName,
    required DownloadableRegion downloadableRegion,
    required Stream<DownloadProgress> stream,
  }) {
    assert(stream.isBroadcast, 'Input stream must be broadcastable');

    _storeName = storeName;
    _downloadableRegion = downloadableRegion;

    _skippedExistingTileCount = 0;
    _skippedSeaTileCount = 0;
    _skippedExistingTileSize = 0;
    _skippedSeaTileSize = 0;

    _rawStream = stream;
    _streamSub = stream.listen(
      (progress) {
        if (progress.attemptedTiles == 0) _isFocused = true;
        _latestEvent = progress;

        final latestTile = progress.latestTileEvent;

        if (latestTile != null && !latestTile.isRepeat) {
          if (latestTile.result == TileEventResult.alreadyExisting) {
            _skippedExistingTileCount++;
            _skippedExistingTileSize += latestTile.tileImage!.lengthInBytes;
          }
          if (latestTile.result == TileEventResult.isSeaTile) {
            _skippedSeaTileCount++;
            _skippedSeaTileSize += latestTile.tileImage!.lengthInBytes;
          }
        }

        notifyListeners();
      },
      onDone: () => _streamSub.cancel(),
    );
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
    notifyListeners();
  }

  StateError get _notReadyError => StateError(
        'Unsafe to retrieve information before a download has been assigned.',
      );
}
