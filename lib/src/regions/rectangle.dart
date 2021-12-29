import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'downloadable_region.dart';

/// A rectangular region with two or more corners
class RectangleRegion implements BaseRegion {
  /// The `LatLngBounds` used to create the rectangle
  final LatLngBounds bounds;

  /// Creates a rectangular region using two or more corners
  RectangleRegion(this.bounds);

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
        points: [bounds.northWest, bounds.southEast],
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        type: RegionType.rectangle,
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
          points: [
            LatLng(
              bounds.southEast.latitude,
              bounds.northWest.longitude,
            ),
            bounds.southEast,
            LatLng(
              bounds.northWest.latitude,
              bounds.southEast.longitude,
            ),
            bounds.northWest,
          ],
        )
      ],
    );
  }

  @override
  List<LatLng> toList() {
    return [
      LatLng(bounds.southEast.latitude, bounds.northWest.longitude),
      bounds.southEast,
      LatLng(bounds.northWest.latitude, bounds.southEast.longitude),
      bounds.northWest,
    ];
  }
}

/// Deprecated due to other available methods. Migrate to construction using the real constructor (`RectangleRegion()`).
@Deprecated(
    'Due to other available methods. Migrate to construction using the real constructor (`RectangleRegion()`).')
extension RectangleRegionExts on LatLngBounds {
  /// Deprecated due to other available methods. Migrate to construction using the real constructor (`RectangleRegion()`).
  @Deprecated(
      'Due to other available methods. Migrate to construction using the real constructor (`RectangleRegion()`).')
  RectangleRegion toRectangleRegion() {
    return RectangleRegion(this);
  }
}
