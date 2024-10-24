// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// A geographically rectangular region based off coordinate bounds
///
/// Does not support skewing into parallelograms: use [CustomPolygonRegion]
/// instead.
class RectangleRegion extends BaseRegion {
  /// Create a geographically rectangular region based off coordinate bounds
  const RectangleRegion(this.bounds);

  /// The coordinate bounds
  final LatLngBounds bounds;

  @override
  DownloadableRegion<RectangleRegion> toDownloadable({
    required int minZoom,
    required int maxZoom,
    required TileLayer options,
    int start = 1,
    int? end,
    Crs crs = const Epsg3857(),
  }) =>
      DownloadableRegion._(
        this,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );

  @override
  List<LatLng> toOutline() =>
      [bounds.northEast, bounds.southEast, bounds.southWest, bounds.northWest];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RectangleRegion && other.bounds == bounds);

  @override
  int get hashCode => bounds.hashCode;
}
