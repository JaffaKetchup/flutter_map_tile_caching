import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../misc/region_selection_method.dart';
import '../misc/region_type.dart';

class DownloaderProvider extends ChangeNotifier {
  RegionSelectionMethod _regionSelectionMethod =
      Platform.isAndroid || Platform.isIOS
          ? RegionSelectionMethod.useMapCenter
          : RegionSelectionMethod.usePointer;
  RegionSelectionMethod get regionSelectionMethod => _regionSelectionMethod;
  set regionSelectionMethod(RegionSelectionMethod newMethod) {
    _regionSelectionMethod = newMethod;
    notifyListeners();
  }

  LatLng _currentNewPointPos = const LatLng(51.509364, -0.128928);
  LatLng get currentNewPointPos => _currentNewPointPos;
  set currentNewPointPos(LatLng newPos) {
    _currentNewPointPos = newPos;
    notifyListeners();
  }

  RegionType _regionType = RegionType.square;
  RegionType get regionType => _regionType;
  set regionType(RegionType newType) {
    _regionType = newType;
    notifyListeners();
  }

  BaseRegion? _region;
  BaseRegion? get region => _region;
  set region(BaseRegion? newRegion) {
    _region = newRegion;
    notifyListeners();
  }

  final List<LatLng> _coordinates = [];
  List<LatLng> get coordinates => List.from(_coordinates);
  List<LatLng> addCoordinate(LatLng coord) {
    _coordinates.add(coord);
    notifyListeners();
    return _coordinates;
  }

  List<LatLng> addCoordinates(Iterable<LatLng> coords) {
    _coordinates.addAll(coords);
    notifyListeners();
    return _coordinates;
  }

  void clearCoordinates() {
    _coordinates.clear();
    _region = null;
    notifyListeners();
  }

  void removeLastCoordinate() {
    _coordinates.removeLast();
    if (_regionType == RegionType.customPolygon
        ? !isCustomPolygonComplete
        : _coordinates.length < 2) _region = null;
    notifyListeners();
  }

  double _lineRadius = 100;
  double get lineRadius => _lineRadius;
  set lineRadius(double newNum) {
    _lineRadius = newNum;
    notifyListeners();
  }

  bool _customPolygonSnap = false;
  bool get customPolygonSnap => _customPolygonSnap;
  set customPolygonSnap(bool newState) {
    _customPolygonSnap = newState;
    notifyListeners();
  }

  bool get isCustomPolygonComplete =>
      _regionType == RegionType.customPolygon &&
      _coordinates.length >= 2 &&
      _coordinates.first == _coordinates.last;

  bool _openAdjustZoomLevelsSlider = false;
  bool get openAdjustZoomLevelsSlider => _openAdjustZoomLevelsSlider;
  set openAdjustZoomLevelsSlider(bool newState) {
    _openAdjustZoomLevelsSlider = newState;
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

  // OLD

  StoreDirectory? _selectedStore;
  StoreDirectory? get selectedStore => _selectedStore;
  void setSelectedStore(StoreDirectory? newStore, {bool notify = true}) {
    _selectedStore = newStore;
    if (notify) notifyListeners();
  }

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
