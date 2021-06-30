import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'downloadableRegion.dart';

/// A rectangular region with two or more corners
class RectangleRegion extends BaseRegion {
  /// The `LatLngBounds` used to create the rectangle
  final LatLngBounds bounds;

  /// Creates a rectangular region using two or more corners
  RectangleRegion(this.bounds);

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
      [this.bounds.northWest, this.bounds.southEast],
      minZoom,
      maxZoom,
      options,
      RegionType.rectangle,
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
          points: [
            LatLng(this.bounds.southEast.latitude,
                this.bounds.northWest.longitude),
            this.bounds.southEast,
            LatLng(this.bounds.northWest.latitude,
                this.bounds.southEast.longitude),
            this.bounds.northWest,
          ],
        )
      ],
    );
  }

  @override
  List<LatLng> toList() {
    return [
      LatLng(this.bounds.southEast.latitude, this.bounds.northWest.longitude),
      this.bounds.southEast,
      LatLng(this.bounds.northWest.latitude, this.bounds.southEast.longitude),
      this.bounds.northWest,
    ];
  }
}

extension rectangleConvert on LatLngBounds {
  /// Converts a `LatLngBounds` to a `RectangleRegion`
  RectangleRegion toRectangleRegion() {
    return RectangleRegion(this);
  }
}
