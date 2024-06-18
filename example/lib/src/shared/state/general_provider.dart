import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class GeneralProvider extends ChangeNotifier {
  Set<String> _currentStores = {};
  Set<String> get currentStores => _currentStores;
  set currentStores(Set<String> newStores) {
    _currentStores = newStores;
    notifyListeners();
  }

  String _urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  String get urlTemplate => _urlTemplate;
  set urlTemplate(String newUrlTemplate) {
    _urlTemplate = newUrlTemplate;
    notifyListeners();
  }

  void removeStore(String store) {
    _currentStores.remove(store);
    notifyListeners();
  }

  void addStore(String store) {
    _currentStores.add(store);
    notifyListeners();
  }

  CacheBehavior get behaviour =>
      switch ((_behaviourPrimary, _behaviourUpdateFromNetwork)) {
        (null, _) => CacheBehavior.cacheOnly,
        (false, false) => CacheBehavior.cacheFirstNoUpdate,
        (false, true) => CacheBehavior.cacheFirst,
        (true, false) => CacheBehavior.onlineFirstNoUpdate,
        (true, true) => CacheBehavior.onlineFirst,
      };

  bool? _behaviourPrimary = false;
  bool? get behaviourPrimary => _behaviourPrimary;
  set behaviourPrimary(bool? newBehaviourPrimary) {
    _behaviourPrimary = newBehaviourPrimary;
    notifyListeners();
  }

  bool _behaviourUpdateFromNetwork = true;
  bool get behaviourUpdateFromNetwork => _behaviourUpdateFromNetwork;
  set behaviourUpdateFromNetwork(bool newBehaviourUpdateFromNetwork) {
    _behaviourUpdateFromNetwork = newBehaviourUpdateFromNetwork;
    notifyListeners();
  }

  bool _displayDebugOverlay = true;
  bool get displayDebugOverlay => _displayDebugOverlay;
  set displayDebugOverlay(bool newDisplayDebugOverlay) {
    _displayDebugOverlay = newDisplayDebugOverlay;
    notifyListeners();
  }

  bool? _storesSelectionMode = true;
  bool? get storesSelectionMode => _storesSelectionMode;
  set storesSelectionMode(bool? newSelectionMode) {
    _storesSelectionMode = newSelectionMode;
    notifyListeners();
  }

  final StreamController<void> resetController = StreamController.broadcast();
  void resetMap() => resetController.add(null);
}
