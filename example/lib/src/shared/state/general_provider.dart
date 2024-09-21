import 'package:flutter/foundation.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../misc/internal_store_read_write_behaviour.dart';
import '../misc/shared_preferences.dart';

class GeneralProvider extends ChangeNotifier {
  AnimatedMapController? _animatedMapController;
  AnimatedMapController get animatedMapController =>
      _animatedMapController ??
      (throw StateError(
        '`(Animated)MapController` must be attached before usage',
      ));
  set animatedMapController(AnimatedMapController controller) {
    _animatedMapController = controller;
    notifyListeners();
  }

  BrowseStoreStrategy? _inheritableBrowseStoreStrategy = () {
    final storedStrategyName = sharedPrefs
        .getString(SharedPrefsKeys.inheritableBrowseStoreStrategy.name);
    if (storedStrategyName case final storedStrategyName?) {
      if (storedStrategyName == '') return null;
      return BrowseStoreStrategy.values.byName(storedStrategyName);
    }
    sharedPrefs.setString(
      SharedPrefsKeys.inheritableBrowseStoreStrategy.name,
      BrowseStoreStrategy.readUpdateCreate.name,
    );
    return BrowseStoreStrategy.readUpdateCreate;
  }();
  BrowseStoreStrategy? get inheritableBrowseStoreStrategy =>
      _inheritableBrowseStoreStrategy;
  set inheritableBrowseStoreStrategy(BrowseStoreStrategy? newStoreStrategy) {
    _inheritableBrowseStoreStrategy = newStoreStrategy;
    sharedPrefs.setString(
      SharedPrefsKeys.inheritableBrowseStoreStrategy.name,
      newStoreStrategy?.name ?? '',
    );
    notifyListeners();
  }

  final Map<String, InternalBrowseStoreStrategy> currentStores = {};
  void changedCurrentStores() => notifyListeners();

  String _urlTemplate =
      sharedPrefs.getString(SharedPrefsKeys.urlTemplate.name) ??
          (() {
            const defaultUrlTemplate =
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
            sharedPrefs.setString(
              SharedPrefsKeys.urlTemplate.name,
              defaultUrlTemplate,
            );
            return defaultUrlTemplate;
          }());
  String get urlTemplate => _urlTemplate;
  set urlTemplate(String newUrlTemplate) {
    _urlTemplate = newUrlTemplate;
    sharedPrefs.setString(SharedPrefsKeys.urlTemplate.name, newUrlTemplate);
    notifyListeners();
  }

  BrowseLoadingStrategy _loadingStrategy = () {
    final storedStrategyName =
        sharedPrefs.getString(SharedPrefsKeys.browseLoadingStrategy.name);
    if (storedStrategyName case final storedStrategyName?) {
      return BrowseLoadingStrategy.values.byName(storedStrategyName);
    }
    sharedPrefs.setString(
      SharedPrefsKeys.browseLoadingStrategy.name,
      BrowseLoadingStrategy.cacheFirst.name,
    );
    return BrowseLoadingStrategy.cacheFirst;
  }();
  BrowseLoadingStrategy get loadingStrategy => _loadingStrategy;
  set loadingStrategy(BrowseLoadingStrategy newLoadingStrategy) {
    _loadingStrategy = newLoadingStrategy;
    sharedPrefs.setString(
      SharedPrefsKeys.browseLoadingStrategy.name,
      newLoadingStrategy.name,
    );
    notifyListeners();
  }

  bool _displayDebugOverlay =
      sharedPrefs.getBool(SharedPrefsKeys.displayDebugOverlay.name) ??
          (() {
            sharedPrefs.setBool(SharedPrefsKeys.displayDebugOverlay.name, true);
            return true;
          }());
  bool get displayDebugOverlay => _displayDebugOverlay;
  set displayDebugOverlay(bool newDisplayDebugOverlay) {
    _displayDebugOverlay = newDisplayDebugOverlay;
    sharedPrefs.setBool(
      SharedPrefsKeys.displayDebugOverlay.name,
      newDisplayDebugOverlay,
    );
    notifyListeners();
  }

  bool _fakeNetworkDisconnect =
      sharedPrefs.getBool(SharedPrefsKeys.fakeNetworkDisconnect.name) ??
          (() {
            sharedPrefs.setBool(
              SharedPrefsKeys.fakeNetworkDisconnect.name,
              false,
            );
            return false;
          }());
  bool get fakeNetworkDisconnect => _fakeNetworkDisconnect;
  set fakeNetworkDisconnect(bool newFakeNetworkDisconnect) {
    _fakeNetworkDisconnect = newFakeNetworkDisconnect;
    sharedPrefs.setBool(
      SharedPrefsKeys.fakeNetworkDisconnect.name,
      newFakeNetworkDisconnect,
    );
    notifyListeners();
  }

  bool _useUnspecifiedAsFallbackOnly = false;
  bool get useUnspecifiedAsFallbackOnly => _useUnspecifiedAsFallbackOnly;
  set useUnspecifiedAsFallbackOnly(bool newUseUnspecifiedAsFallbackOnly) {
    _useUnspecifiedAsFallbackOnly = newUseUnspecifiedAsFallbackOnly;
    notifyListeners();
  }
}
