import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../shared/misc/region_selection_method.dart';
import '../../../../../shared/misc/region_type.dart';

class RegionSelectionProvider extends ChangeNotifier {
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
    if (_coordinates.isNotEmpty) _coordinates.removeLast();
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

  int _minZoom = 0;
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

  FMTCStore? _selectedStore;
  FMTCStore? get selectedStore => _selectedStore;
  void setSelectedStore(FMTCStore? newStore, {bool notify = true}) {
    _selectedStore = newStore;
    if (notify) notifyListeners();
  }
}
