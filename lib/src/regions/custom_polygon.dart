// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A geographical region who's outline is defined by a list of coordinates
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - list of [LatLng]s forming the outline: [toOutline]
class CustomPolygonRegion extends BaseRegion {
  /// A geographical region who's outline is defined by a list of coordinates
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - list of [LatLng]s forming the outline: [toOutline]
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

  /// **Deprecated.** Instead obtain the outline/line/points using other methods,
  /// and render the layer manually. This method is being removed to reduce
  /// dependency on flutter_map, and allow full usage of flutter_map
  /// functionality without it needing to be semi-implemented here. This feature
  /// was deprecated after v9.1.0, and will be removed in the next breaking/major
  /// release.
  @Deprecated(
    'Instead obtain the outline/line/points using other methods, and render the '
    'layer manually.  '
    'This method is being removed to reduce dependency on flutter_map, and allow '
    'full usage of flutter_map functionality without it needing to be '
    'semi-implemented here. '
    'This feature was deprecated after v9.1.0, and will be removed in the next '
    'breaking/major release.',
  )
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
            points: outline,
            color: fillColor,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
            pattern: isDotted
                ? const StrokePattern.dotted()
                : const StrokePattern.solid(),
            label: label,
            labelStyle: labelStyle,
            labelPlacement: labelPlacement,
          ),
        ],
      );

  @override
  List<LatLng> toOutline() => outline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomPolygonRegion && listEquals(outline, other.outline));

  @override
  int get hashCode => outline.hashCode;
}
