// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// A geographical region who's outline is defined by a list of coordinates
class CustomPolygonRegion extends BaseRegion {
  /// Create a geographical region who's outline is defined by a list of
  /// coordinates
  const CustomPolygonRegion(this.outline);

  /// The outline coordinates
  final List<LatLng> outline;

  @override
  DownloadableRegion<CustomPolygonRegion> toDownloadable({
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
  List<LatLng> toOutline() => outline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomPolygonRegion && listEquals(outline, other.outline));

  @override
  int get hashCode => Object.hashAll(outline);
}
