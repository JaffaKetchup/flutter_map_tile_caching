import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart'
    show Polygon, PolygonLayerOptions, TileLayerOptions;
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import 'downloadableRegion.dart';

/// Creates a circular region
class CircleRegion {
  /// The center of the circle as a `LatLng`
  final LatLng center;

  /// The radius of the circle as a `double` in km
  final double radius;

  CircleRegion(this.center, this.radius);
}

List<LatLng> _circleToOutline(
    double lat, double lon, double d, int circleDegrees) {
  final List<LatLng> output = [];
  for (int x = 0; x <= circleDegrees; x++) {
    double brng = x * math.pi / 180;
    final double latRadians = math.asin(math.sin(lat) * math.cos(d) +
        math.cos(lat) * math.sin(d) * math.cos(brng));
    final double lngRadians = lon +
        math.atan2(math.sin(brng) * math.sin(d) * math.cos(lat),
            math.cos(d) - math.sin(lat) * math.sin(latRadians));

    output.add(LatLng(latRadians * 180 / math.pi, lngRadians * 180 / math.pi));
  }

  return output;
}

/// A number of extensions for a circular region
extension circleExt on CircleRegion {
  /// Create a downloadable region out of this region
  ///
  /// Returns a `DownloadableRegion` to be passed to the `StorageCachingTileProvider().downloadRegion()` function
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
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
      errorHandler,
    );
  }

  /// Create a list of all the `LatLng`s on every degree of the outline of this region
  ///
  /// Returns a `List<LatLng>` which can be used anywhere
  List<LatLng> toList([int circleDegrees = 360]) {
    return _circleToOutline(
      this.center.latitudeInRad,
      this.center.longitudeInRad,
      this.radius / 1.852 / 3437.670013352,
      circleDegrees,
    );
  }

  /// Create a drawable area for `FlutterMap()` out of this region
  ///
  /// Returns a `PolygonLayerOptions` to be added to the `layer` property of a `FlutterMap()`
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
}
