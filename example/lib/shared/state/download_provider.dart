import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../vars/region_mode.dart';

class DownloadProvider extends ChangeNotifier {
  RegionMode _regionMode = RegionMode.square;
  RegionMode get regionMode => _regionMode;
  set regionMode(RegionMode newMode) {
    _regionMode = newMode;
    notifyListeners();
  }

  double _lineRegionRadius = 1000;
  double get lineRegionRadius => _lineRegionRadius;
  set lineRegionRadius(double newNum) {
    _lineRegionRadius = newNum;
    notifyListeners();
  }

  List<LatLng> _lineRegionPoints = [];
  List<LatLng> get lineRegionPoints => _lineRegionPoints;
  set lineRegionPoints(List<LatLng> newList) {
    _lineRegionPoints = newList;
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

  int _parallelThreads = 5;
  int get parallelThreads => _parallelThreads;
  set parallelThreads(int newNum) {
    _parallelThreads = newNum;
    notifyListeners();
  }

  int _bufferingAmount = 100;
  int get bufferingAmount => _bufferingAmount;
  set bufferingAmount(int newNum) {
    _bufferingAmount = newNum;
    notifyListeners();
  }

  bool _skipExistingTiles = true;
  bool get skipExistingTiles => _skipExistingTiles;
  set skipExistingTiles(bool newBool) {
    _skipExistingTiles = newBool;
    notifyListeners();
  }

  bool _skipSeaTiles = true;
  bool get skipSeaTiles => _skipSeaTiles;
  set skipSeaTiles(bool newBool) {
    _skipSeaTiles = newBool;
    notifyListeners();
  }

  int? _rateLimit = 200;
  int? get rateLimit => _rateLimit;
  set rateLimit(int? newNum) {
    _rateLimit = newNum;
    notifyListeners();
  }

  bool _disableRecovery = false;
  bool get disableRecovery => _disableRecovery;
  set disableRecovery(bool newBool) {
    _disableRecovery = newBool;
    notifyListeners();
  }

  final List<TileEvent> _failedTiles = [];
  List<TileEvent> get failedTiles => _failedTiles;
  void addFailedTile(TileEvent e) => _failedTiles.add(e);
}
