import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'downloadableRegion.dart';

/// A region containing 4 points representing the corners of a rectangle
class DiagonalRectangleRegion extends BaseRegion {
  /// The points of the rectangle in the order top-left > top-right > bottom-right > bottom-left
  final List<LatLng> points;

  /// Creates a region containing 4 points representing the corners of a rectangle
  DiagonalRectangleRegion(this.points);

  @override
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  }) {
    assert(minZoom <= maxZoom, 'minZoom is more than maxZoom');
    return DownloadableRegion(
      points,
      minZoom,
      maxZoom,
      options,
      RegionType.diagonalRectangle,
      errorHandler: errorHandler,
      crs: crs,
      tileSize: tileSize,
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
          points: points,
        ),
      ],
    );
  }

  @override
  @internal
  List<LatLng> toList() {
    return points;
  }
}
