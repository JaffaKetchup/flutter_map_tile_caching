// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A geographically rectangular region based off coordinate bounds
///
/// Rectangles do not support skewing into parallelograms.
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - [Widget] layer to be placed in a map: [toDrawable]
///  - list of [LatLng]s forming the outline: [toOutline]
class RectangleRegion extends BaseRegion {
  /// A geographically rectangular region based off coordinate bounds
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - [Widget] layer to be placed in a map: [toDrawable]
  ///  - list of [LatLng]s forming the outline: [toOutline]
  RectangleRegion(this.bounds, {super.name}) : super();

  /// The coordinate bounds
  final LatLngBounds bounds;

  @override
  DownloadableRegion<RectangleRegion> toDownloadable({
    required int minZoom,
    required int maxZoom,
    required TileLayer options,
    int start = 0,
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
            points: toOutline(),
          ),
        ],
      );

  @override
  List<LatLng> toOutline() =>
      [bounds.northEast, bounds.southEast, bounds.southWest, bounds.northWest];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RectangleRegion && other.bounds == bounds && super == other);

  @override
  int get hashCode => Object.hash(bounds, super.hashCode);
}
