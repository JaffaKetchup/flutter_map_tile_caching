import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../misc/internal_store_read_write_behaviour.dart';

class GeneralProvider extends ChangeNotifier {
  StoreReadWriteBehaviour? _inheritableStoreReadWriteBehaviour =
      StoreReadWriteBehaviour.readUpdateCreate;
  StoreReadWriteBehaviour? get inheritableStoreReadWriteBehaviour =>
      _inheritableStoreReadWriteBehaviour;
  set inheritableStoreReadWriteBehaviour(
    StoreReadWriteBehaviour? newBehaviour,
  ) {
    _inheritableStoreReadWriteBehaviour = newBehaviour;
    notifyListeners();
  }

  final Map<String, InternalStoreReadWriteBehaviour> currentStores = {};
  void changedCurrentStores() => notifyListeners();

  String _urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  String get urlTemplate => _urlTemplate;
  set urlTemplate(String newUrlTemplate) {
    _urlTemplate = newUrlTemplate;
    notifyListeners();
  }

  CacheBehavior _cacheBehavior = CacheBehavior.cacheFirst;
  CacheBehavior get cacheBehavior => _cacheBehavior;
  set cacheBehavior(CacheBehavior newCacheBehavior) {
    _cacheBehavior = newCacheBehavior;
    notifyListeners();
  }

  bool _displayDebugOverlay = true;
  bool get displayDebugOverlay => _displayDebugOverlay;
  set displayDebugOverlay(bool newDisplayDebugOverlay) {
    _displayDebugOverlay = newDisplayDebugOverlay;
    notifyListeners();
  }
}
