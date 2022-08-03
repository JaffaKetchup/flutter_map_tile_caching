import 'dart:async';

import 'package:flutter/foundation.dart';

class GeneralProvider extends ChangeNotifier {
  String? _currentStore;
  String? get currentStore => _currentStore;
  set currentStore(String? newStore) {
    _currentStore = newStore;
    notifyListeners();
  }

  final StreamController<void> resetController = StreamController.broadcast();
  void resetMap() => resetController.add(null);
}
