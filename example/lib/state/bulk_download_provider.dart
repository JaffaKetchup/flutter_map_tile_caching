import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../pages/bulk_downloader/components/region_constraints.dart';
import '../pages/bulk_downloader/components/region_mode.dart';

class BulkDownloadProvider extends ChangeNotifier {
  // I hate state management
  RegionConstraints? region; // Problem-causer 9000

  RegionMode _mode = RegionMode.Square;
  RegionMode get mode => _mode;
  set mode(RegionMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  bool _regionSelected = false;
  bool get regionSelected => _regionSelected;
  set regionSelected(bool newBool) {
    _regionSelected = newBool;
    notifyListeners();
  }

  LatLngBounds _testingBounds = LatLngBounds(LatLng(0, 0), LatLng(0, 0));
  LatLngBounds get testingBounds => _testingBounds;
  set testingBounds(LatLngBounds newBounds) {
    _testingBounds = newBounds;
    notifyListeners();
  }

  List<LatLng> _centerAndEdge = List<LatLng>.filled(2, LatLng(0,0));
  List<LatLng> get centerAndEdge => _centerAndEdge;
  set centerAndEdge(List<LatLng> newCenterAndEdge) {
    _centerAndEdge = newCenterAndEdge;
    notifyListeners();
  }

}
