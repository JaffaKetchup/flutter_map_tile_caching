import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../vars/region_mode.dart';

class DownloadProvider extends ChangeNotifier {
  RegionMode _regionMode = RegionMode.square;
  RegionMode get regionMode => _regionMode;
  set regionMode(RegionMode newMode) {
    _regionMode = newMode;
    notifyListeners();
  }

  BaseRegion? _region;
  BaseRegion? get region => _region;
  set region(BaseRegion? newRegion) {
    _region = newRegion;
    notifyListeners();
  }

  int? _regionTiles;
  int? get regionTiles => _regionTiles;
  set regionTiles(int? newNum) {
    _regionTiles = newNum;
    notifyListeners();
  }

  int _minZoom = 1;
  int get minZoom => _minZoom;
  set minZoom(int newNum) {
    _minZoom = newNum;
    notifyListeners();
  }

  int _maxZoom = 16;
  int get maxZoom => _maxZoom;
  set maxZoom(int newNum) {
    _maxZoom = newNum;
    notifyListeners();
  }

  StoreDirectory? _selectedStore;
  StoreDirectory? get selectedStore => _selectedStore;
  void setSelectedStore(StoreDirectory? newStore, {bool notify = true}) {
    _selectedStore = newStore;
    if (notify) notifyListeners();
  }

  final StreamController<void> _manualPolygonRecalcTrigger =
      StreamController.broadcast();
  StreamController<void> get manualPolygonRecalcTrigger =>
      _manualPolygonRecalcTrigger;
  void triggerManualPolygonRecalc() => _manualPolygonRecalcTrigger.add(null);

  Stream<DownloadProgress>? _downloadProgress;
  Stream<DownloadProgress>? get downloadProgress => _downloadProgress;
  void setDownloadProgress(
    Stream<DownloadProgress>? newStream, {
    bool notify = true,
  }) {
    _downloadProgress = newStream;
    if (notify) notifyListeners();
  }

  bool _preventRedownload = false;
  bool get preventRedownload => _preventRedownload;
  set preventRedownload(bool newBool) {
    _preventRedownload = newBool;
    notifyListeners();
  }

  bool _seaTileRemoval = true;
  bool get seaTileRemoval => _seaTileRemoval;
  set seaTileRemoval(bool newBool) {
    _seaTileRemoval = newBool;
    notifyListeners();
  }

  bool _disableRecovery = false;
  bool get disableRecovery => _disableRecovery;
  set disableRecovery(bool newBool) {
    _disableRecovery = newBool;
    notifyListeners();
  }
}
