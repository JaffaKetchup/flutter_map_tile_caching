import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

extension LatLngExts on LatLng {
  /// Prefer usage of operator `>>` or `latlong2`'s `Distance()` methods
  ///
  /// Calculate distance to another LatLng in km using average Earth radius
  double distanceTo(LatLng b) {
    final double p = 0.017453292519943295;
    final double formula = 0.5 -
        math.cos((b.latitude - this.latitude) * p) / 2 +
        math.cos(this.latitude * p) *
            math.cos(b.latitude * p) *
            (1 - math.cos((b.longitude - this.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(formula)) * 1000;
  }

  /// Calculate distance to another LatLng in km using average Earth radius
  ///
  /// Not to be confused with a bitwise operator, which does not exist for this object.
  double operator >>(LatLng point) {
    return this.distanceTo(point);
  }
}

extension IntExts on int {
  /*
  /// Convert degrees to radians
  double get degToRad => this * math.pi / 180;

  /// Convert radians to degrees
  double get radToDeg => this * 180 / math.pi;
  */

  /// Convert a number of bytes to a number of megabytes (real, uses 1024 basis)
  ///
  /// Useful after getting a cache store size
  double get bytesToMegabytes => this / 1049000;
}
