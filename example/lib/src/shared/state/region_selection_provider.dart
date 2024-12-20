import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

enum RegionSelectionMethod {
  useMapCenter,
  usePointer,
}

enum RegionType {
  rectangle,
  circle,
  line,
  customPolygon,
}

class RegionSelectionProvider extends ChangeNotifier {
  RegionSelectionMethod _currentRegionSelectionMethod =
      Platform.isAndroid || Platform.isIOS
          ? RegionSelectionMethod.useMapCenter
          : RegionSelectionMethod.usePointer;
  RegionSelectionMethod get regionSelectionMethod =>
      _currentRegionSelectionMethod;
  set regionSelectionMethod(RegionSelectionMethod newMethod) {
    _currentRegionSelectionMethod = newMethod;
    notifyListeners();
  }

  LatLng? _currentNewPointPos;
  LatLng? get currentNewPointPos => _currentNewPointPos;
  set currentNewPointPos(LatLng? newPos) {
    _currentNewPointPos = newPos;
    notifyListeners();
  }

  RegionType _currentRegionType = RegionType.rectangle;
  RegionType get currentRegionType => _currentRegionType;
  set currentRegionType(RegionType newType) {
    _currentRegionType = newType;
    notifyListeners();
  }

  final _constructedRegions = <BaseRegion, HSLColor>{};
  Map<BaseRegion, HSLColor> get constructedRegions =>
      Map.unmodifiable(_constructedRegions);

  void addConstructedRegion(BaseRegion region) {
    assert(region is! MultiRegion, 'Cannot be a `MultiRegion`');

    HSLColor generateUnusedRandomColor({int iteration = 0}) {
      final color = HSLColor.fromAHSL(1, Random().nextDouble() * 360, 1, 0.5);

      if (iteration > 18) return color;

      for (final usedColor in _constructedRegions.values) {
        final diff = (color.hue - usedColor.hue).abs();
        if (diff > 20) continue;
        return generateUnusedRandomColor(iteration: iteration + 1);
      }

      return color;
    }

    _constructedRegions[region] = generateUnusedRandomColor();

    _currentConstructingCoordinates.clear();

    notifyListeners();
  }

  void removeConstructedRegion(BaseRegion region) {
    _constructedRegions.remove(region);
    notifyListeners();
  }

  void clearConstructedRegions() {
    _constructedRegions.clear();
    notifyListeners();
  }

  final List<LatLng> _currentConstructingCoordinates = [];
  List<LatLng> get currentConstructingCoordinates =>
      List.unmodifiable(_currentConstructingCoordinates);
  List<LatLng> addCoordinate(LatLng coord) {
    _currentConstructingCoordinates.add(coord);
    notifyListeners();
    return _currentConstructingCoordinates;
  }

  List<LatLng> addCoordinates(Iterable<LatLng> coords) {
    _currentConstructingCoordinates.addAll(coords);
    notifyListeners();
    return _currentConstructingCoordinates;
  }

  void clearCoordinates() {
    _currentConstructingCoordinates.clear();
    notifyListeners();
  }

  void removeLastCoordinate() {
    if (_currentConstructingCoordinates.isNotEmpty) {
      _currentConstructingCoordinates.removeLast();
    }
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

  bool _isDownloadSetupPanelVisible = false;
  bool get isDownloadSetupPanelVisible => _isDownloadSetupPanelVisible;
  set isDownloadSetupPanelVisible(bool newState) {
    _isDownloadSetupPanelVisible = newState;
    notifyListeners();
  }
}
