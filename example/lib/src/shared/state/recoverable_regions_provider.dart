import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class RecoverableRegionsProvider extends ChangeNotifier {
  var _failedRegions = <RecoveredRegion<MultiRegion>, HSLColor>{};
  UnmodifiableMapView<RecoveredRegion<MultiRegion>, HSLColor>
      get failedRegions => UnmodifiableMapView(_failedRegions);
  set failedRegions(Map<RecoveredRegion<MultiRegion>, HSLColor> newState) {
    _failedRegions = newState;
    notifyListeners();
  }
}
