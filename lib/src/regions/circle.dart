import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'downloadableRegion.dart';

/// A circular region with a center point and a radius
class CircleRegion extends BaseRegion {
  /// The center of the circle as a `LatLng`
  final LatLng center;

  /// The radius of the circle as a `double` in km
  final double radius;

  /// Creates a circular region using a center point and a radius
  CircleRegion(this.center, this.radius);

  @override
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    bool preventRedownload = false,
    Color? seaColor,
    int compressionQuality = -1,
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
    @Deprecated('\'circleDegrees\' has been deprecated, and will be removed in the next release. There is no newer alternative for bug safety. You should remove this parameter from your code and let it take the default (and future fixed value) 360.')
        int circleDegrees = 360,
  }) {
    return DownloadableRegion(
      _circleToOutline(
        this.center.latitudeInRad,
        this.center.longitudeInRad,
        this.radius / 1.852 / 3437.670013352,
        circleDegrees,
      ),
      minZoom,
      maxZoom,
      options,
      RegionType.circle,
      errorHandler: errorHandler,
      crs: crs,
    );
  }

  @override
  PolygonLayerOptions toDrawable(
    Color fillColor,
    Color borderColor, {
    double borderStrokeWidth = 3.0,
    bool isDotted = false,
  }) {
    return PolygonLayerOptions(
      polygons: [
        Polygon(
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: borderStrokeWidth,
          isDotted: isDotted,
          points: this.toList(),
        )
      ],
    );
  }

  @override
  List<LatLng> toList([
    @Deprecated('\'circleDegrees\' has been deprecated, and will be removed in the next release. There is no newer alternative for bug safety. You should remove this parameter from your code and let it take the default (and future fixed value) 360.')
        int deprecated = 360,
  ]) {
    return _circleToOutline(
      this.center.latitudeInRad,
      this.center.longitudeInRad,
      this.radius / 1.852 / 3437.670013352,
      deprecated,
    );
  }
}

List<LatLng> _circleToOutline(
  double lat,
  double lon,
  double d,
  int circleDegrees,
) {
  final List<LatLng> output = [];
  for (int x = 0; x <= circleDegrees; x++) {
    double brng = x * math.pi / 180;
    final double latRadians = math.asin(math.sin(lat) * math.cos(d) +
        math.cos(lat) * math.sin(d) * math.cos(brng));
    final double lngRadians = lon +
        math.atan2(math.sin(brng) * math.sin(d) * math.cos(lat),
            math.cos(d) - math.sin(lat) * math.sin(latRadians));

    output.add(
      LatLng(
        latRadians * 180 / math.pi,
        (lngRadians * 180 / math.pi).clamp(-180, 180),
      ),
    );
  }

  return output;
}

extension circleConvert on LatLng {
  /// Converts a `LatLng` to a `CircleRegion` given a radius in km
  CircleRegion toCircleRegion(double radius) {
    return CircleRegion(this, radius);
  }
}
