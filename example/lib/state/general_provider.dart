import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class GeneralProvider extends ChangeNotifier {
  bool _cachingEnabled = false;
  bool get cachingEnabled => _cachingEnabled;
  set cachingEnabled(bool newVal) {
    _cachingEnabled = newVal;
    notifyListeners();
  }

  String _storeName = 'Default Store';
  String get storeName => _storeName;
  set storeName(String newVal) {
    _storeName = newVal;
    notifyListeners();
  }

  late MapCachingManager _currentMapCachingManager;
  MapCachingManager get currentMapCachingManager => _currentMapCachingManager;
  set currentMapCachingManager(MapCachingManager newVal) {
    _currentMapCachingManager = newVal;
    notifyListeners();
  }

  set newMapCachingManager(MapCachingManager newVal) {
    _currentMapCachingManager = newVal;
  }

  StreamController<Null> _resetController = StreamController.broadcast();
  StreamController<Null> get resetController => _resetController;
  void resetMap() {
    _resetController.add(null);
  }
}
