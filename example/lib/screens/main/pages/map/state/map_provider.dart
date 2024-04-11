import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

typedef AnimateToSignature = Future<void> Function({
  LatLng? dest,
  double? zoom,
  Offset offset,
  double? rotation,
  Curve? curve,
  String? customId,
});

class MapProvider extends ChangeNotifier {
  MapController _mapController = MapController();
  MapController get mapController => _mapController;
  set mapController(MapController newController) {
    _mapController = newController;
    notifyListeners();
  }

  late AnimateToSignature? _animateTo;
  AnimateToSignature get animateTo => _animateTo!;
  set animateTo(AnimateToSignature newMethod) {
    _animateTo = newMethod;
    notifyListeners();
  }
}
