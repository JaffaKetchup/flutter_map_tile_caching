import 'package:flutter/foundation.dart';

import '../pages/bulk_downloader/components/region_constraints.dart';
import '../pages/bulk_downloader/components/region_mode.dart';

class BulkDownloadProvider extends ChangeNotifier {
  RegionConstraints? region; // Problem-causer 9000 - DONT TOUCH

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
}
