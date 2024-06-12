import 'dart:async';

import 'package:flutter/foundation.dart';

class GeneralProvider extends ChangeNotifier {
  Set<String> _currentStores = {};
  Set<String> get currentStores => _currentStores;
  set currentStores(Set<String> newStores) {
    _currentStores = newStores;
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

  bool? _storesSelectionMode = true;
  bool? get storesSelectionMode => _storesSelectionMode;
  set storesSelectionMode(bool? newSelectionMode) {
    _storesSelectionMode = newSelectionMode;
    notifyListeners();
  }

  final StreamController<void> resetController = StreamController.broadcast();
  void resetMap() => resetController.add(null);
}
