import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'downloadable_region.dart';

/// A circular region with a center point and a radius
class CircleRegion implements BaseRegion {
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
    int parallelThreads = 10,
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    int start = 0,
    int? end,
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
  }) =>
      DownloadableRegion.internal(
        points: toList(),
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        type: RegionType.circle,
        originalRegion: this,
        parallelThreads: parallelThreads,
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        start: start,
        end: end,
        crs: crs,
        errorHandler: errorHandler,
      );

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
          points: toList(),
        )
      ],
    );
  }

  @override
  List<LatLng> toList() {
    final double rad = radius / 1.852 / 3437.670013352;
    final double lat = center.latitudeInRad;
    final double lon = center.longitudeInRad;
    final List<LatLng> output = [];

    for (int x = 0; x <= 360; x++) {
      final double brng = x * math.pi / 180;
      final double latRadians = math.asin(
        math.sin(lat) * math.cos(rad) +
            math.cos(lat) * math.sin(rad) * math.cos(brng),
      );
      final double lngRadians = lon +
          math.atan2(
            math.sin(brng) * math.sin(rad) * math.cos(lat),
            math.cos(rad) - math.sin(lat) * math.sin(latRadians),
          );

      output.add(
        LatLng(
          latRadians * 180 / math.pi,
          (lngRadians * 180 / math.pi)
              .clamp(-180, 180), // Clamped to fix errors with flutter_map
        ),
      );
    }

    return output;
  }
}
