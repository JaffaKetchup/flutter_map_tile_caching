import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences sharedPrefs;

enum SharedPrefsKeys {
  mapLocationLat,
  mapLocationLng,
  mapLocationZoom,
  customNonStoreUrls,
  urlTemplate,
  inheritableBrowseStoreStrategy,
  browseLoadingStrategy,
  displayDebugOverlay,
  fakeNetworkDisconnect,
}
