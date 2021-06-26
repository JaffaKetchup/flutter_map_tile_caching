import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart'
    show LatLngBounds, Polygon, PolygonLayerOptions, TileLayerOptions;

import 'package:latlong2/latlong.dart';

import 'downloadableRegion.dart';

class SquareRegion {
  final LatLngBounds bounds;

  SquareRegion(this.bounds);
}

extension squareExt on SquareRegion {
  /// Create a downloadable region out of this region
  ///
  /// Returns a `DownloadableRegion` to be passed to the `StorageCachingTileProvider().downloadRegion()` function
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
  }) {
    return DownloadableRegion(
      [this.bounds.northWest, this.bounds.southEast],
      minZoom,
      maxZoom,
      options,
      RegionType.square,
      errorHandler,
    );
  }

  /// Create a list of all the `LatLng`s on every corner of the outline of this region
  ///
  /// Returns a `List<LatLng?>` which can be used anywhere
  List<LatLng?> toList() {
    return [
      this.bounds.southWest,
      this.bounds.southEast,
      this.bounds.northEast,
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
