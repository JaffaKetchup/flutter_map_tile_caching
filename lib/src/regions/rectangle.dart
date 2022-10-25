// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'base_region.dart';
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
    TileLayer options, {
    int parallelThreads = 10,
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    int start = 0,
    int? end,
    Crs crs = const Epsg3857(),
    void Function(Object?)? errorHandler,
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
  PolygonLayer toDrawable({
    Color? fillColor,
    Color borderColor = const Color(0x00000000),
    double borderStrokeWidth = 3.0,
    bool isDotted = false,
    String? label,
    TextStyle labelStyle = const TextStyle(),
    PolygonLabelPlacement labelPlacement = PolygonLabelPlacement.polylabel,
  }) =>
      PolygonLayer(
        polygons: [
          Polygon(
            isFilled: fillColor != null,
            color: fillColor ?? Colors.transparent,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
            isDotted: isDotted,
            label: label,
            labelStyle: labelStyle,
            labelPlacement: labelPlacement,
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

  @override
  List<LatLng> toList() => [
        LatLng(bounds.southEast.latitude, bounds.northWest.longitude),
        bounds.southEast,
        LatLng(bounds.northWest.latitude, bounds.southEast.longitude),
        bounds.northWest,
      ];
}
