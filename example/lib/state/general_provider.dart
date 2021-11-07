import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class GeneralProvider extends ChangeNotifier {
  bool _cachingEnabled = false;
  bool get cachingEnabled => _cachingEnabled;
  set cachingEnabled(bool newVal) {
    _cachingEnabled = newVal;
    notifyListeners();
  }

  bool _offlineMode = false;
  bool get offlineMode => _offlineMode;
  set offlineMode(bool newVal) {
    _offlineMode = newVal;
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
}
