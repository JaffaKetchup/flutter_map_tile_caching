import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

class MapProvider extends ChangeNotifier {
  MapController _mapController = MapController();
  MapController get mapController => _mapController;
  set mapController(MapController newController) {
    _mapController = newController;
    notifyListeners();
  }
}
