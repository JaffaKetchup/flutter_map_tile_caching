import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../misc/internal_store_read_write_behaviour.dart';

class GeneralProvider extends ChangeNotifier {
  BrowseStoreStrategy? _inheritableBrowseStoreStrategy =
      BrowseStoreStrategy.readUpdateCreate;
  BrowseStoreStrategy? get inheritableBrowseStoreStrategy =>
      _inheritableBrowseStoreStrategy;
  set inheritableBrowseStoreStrategy(BrowseStoreStrategy? newStoreStrategy) {
    _inheritableBrowseStoreStrategy = newStoreStrategy;
    notifyListeners();
  }

  final Map<String, InternalBrowseStoreStrategy> currentStores = {};
  void changedCurrentStores() => notifyListeners();

  String _urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  String get urlTemplate => _urlTemplate;
  set urlTemplate(String newUrlTemplate) {
    _urlTemplate = newUrlTemplate;
    notifyListeners();
  }

  BrowseLoadingStrategy _loadingStrategy = BrowseLoadingStrategy.cacheFirst;
  BrowseLoadingStrategy get loadingStrategy => _loadingStrategy;
  set loadingStrategy(BrowseLoadingStrategy newLoadingStrategy) {
    _loadingStrategy = newLoadingStrategy;
    notifyListeners();
  }

  bool _displayDebugOverlay = true;
  bool get displayDebugOverlay => _displayDebugOverlay;
  set displayDebugOverlay(bool newDisplayDebugOverlay) {
    _displayDebugOverlay = newDisplayDebugOverlay;
    notifyListeners();
  }
}
