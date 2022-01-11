// ignore_for_file: prefer_void_to_null

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'package:shared_preferences/shared_preferences.dart';

class GeneralProvider extends ChangeNotifier {
  //! CACHING !//

  bool _cachingEnabled = false;
  bool get cachingEnabled => _cachingEnabled;
  set cachingEnabled(bool newVal) {
    _cachingEnabled = newVal;
    notifyListeners();
  }

  String _storeName = 'Default Store';
  String get storeName => _storeName;
  set storeNameQuiet(String newVal) => _storeName = newVal;
  set storeName(String newVal) {
    _storeName = newVal;
    notifyListeners();
  }

  Directory? parentDirectory; // Should only be set once
  SharedPreferences? persistent; // Should only be set once

  //! MISC !//

  final StreamController<Null> _resetController = StreamController.broadcast();
  StreamController<Null> get resetController => _resetController;
  void resetMap() {
    _resetController.add(null);
  }
}
