import 'package:flutter/foundation.dart';
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

  List<LatLng> _centerAndEdge = List.filled(2, LatLng(0, 0));
  List<LatLng> get centerAndEdge => _centerAndEdge;
  set centerAndEdge(List<LatLng> newCenterAndEdge) {
    _centerAndEdge = newCenterAndEdge;
    notifyListeners();
  }

  List<int> _minMaxZoom = [1, 16];
  List<int> get minMaxZoom => _minMaxZoom;
  set minMaxZoom(List<int> newMinMaxZoom) {
    _minMaxZoom = newMinMaxZoom;
    notifyListeners();
  }

  int _parallelThreads = 5;
  int get parallelThreads => _parallelThreads;
  set parallelThreads(int newNum) {
    _parallelThreads = newNum;
    notifyListeners();
  }

  bool _backgroundDownloading = false;
  bool get backgroundDownloading => _backgroundDownloading;
  set backgroundDownloading(bool newBool) {
    _backgroundDownloading = newBool;
    notifyListeners();
  }

  bool _preventRedownload = true;
  bool get preventRedownload => _preventRedownload;
  set preventRedownload(bool newBool) {
    _preventRedownload = newBool;
    notifyListeners();
  }

  bool _seaTileRemoval = true;
  bool get seaTileRemoval => _seaTileRemoval;
  set seaTileRemoval(bool newBool) {
    _seaTileRemoval = newBool;
    notifyListeners();
  }
}
