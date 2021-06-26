import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart'
    show LatLngBounds, Polygon, PolygonLayerOptions, TileLayerOptions;
import 'package:latlong2/latlong.dart';

import 'downloadableRegion.dart';

/// Creates a rectangular region using two or more corners
class RectangleRegion {
  /// The `LatLngBounds` used to create the rectangle
  final LatLngBounds bounds;

  /// Creates a rectangular region using two or more corners
  RectangleRegion(this.bounds);
}

extension rectangleExt on RectangleRegion {
  /// Create a downloadable region out of this region
  ///
  /// Returns a `DownloadableRegion` to be passed to the `StorageCachingTileProvider().downloadRegion()` function
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
  }) {
    assert(minZoom <= maxZoom, 'minZoom is more than maxZoom');
    return DownloadableRegion(
      [this.bounds.northWest, this.bounds.southEast],
      minZoom,
      maxZoom,
      options,
      RegionType.rectangle,
      errorHandler,
    );
  }

  /// Create a list of all the `LatLng`s on every corner of the outline of this region
  ///
  /// Returns a `List<LatLng>` which can be used anywhere
  List<LatLng> toList() {
    return [
      LatLng(this.bounds.southEast.latitude, this.bounds.northWest.longitude),
      this.bounds.southEast,
      LatLng(this.bounds.northWest.latitude, this.bounds.southEast.longitude),
      this.bounds.northWest,
    ];
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
}

extension rectangleConvert on LatLngBounds {
  /// Converts a `LatLngBounds` to a `RectangleRegion`
  RectangleRegion toRectangleRegion() {
    return RectangleRegion(this);
  }
}
