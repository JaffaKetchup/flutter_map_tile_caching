import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

extension latlngExts on LatLng {
  /// Calculate distance to another LatLng in km
  ///
  /// Uses average Earth radius, so not very accurate.
  double distanceTo(LatLng point) {
    final double dLat = (point.latitude - this.latitude).degToRad<double>();
    final double dLon = (point.longitude - this.longitude).degToRad<double>();

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(this.latitudeInRad) *
            math.cos(point.latitudeInRad);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return 6371 * c;
  }
}

extension degRad on num {
  /// Convert degrees to radians
  T degToRad<T>() {
    return (this * math.pi / 180) as T;
  }

  /// Convert radians to degrees
  T radToDeg<T>() {
    return (this * 180 / math.pi) as T;
  }
}
