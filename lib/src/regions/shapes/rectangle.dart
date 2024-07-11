// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../flutter_map_tile_caching.dart';

/// A geographically rectangular region based off coordinate bounds
///
/// Rectangles do not support skewing into parallelograms.
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - list of [LatLng]s forming the outline: [toOutline]
class RectangleRegion extends BaseRegion {
  /// A geographically rectangular region based off coordinate bounds
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - list of [LatLng]s forming the outline: [toOutline]
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
