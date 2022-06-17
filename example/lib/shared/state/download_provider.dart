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

  final StreamController<void> _manualPolygonRecalcTrigger =
      StreamController.broadcast();
  StreamController<void> get manualPolygonRecalcTrigger =>
      _manualPolygonRecalcTrigger;
  void triggerManualPolygonRecalc() {
    _manualPolygonRecalcTrigger.add(null);
  }
}
