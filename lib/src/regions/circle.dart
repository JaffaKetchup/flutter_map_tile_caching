// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A geographically circular region based off a [center] coord and [radius]
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - [Widget] layer to be placed in a map: [toDrawable]
///  - list of [LatLng]s forming the outline: [toOutline]
class CircleRegion extends BaseRegion {
  /// A geographically circular region based off a [center] coord and [radius]
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - [Widget] layer to be placed in a map: [toDrawable]
  ///  - list of [LatLng]s forming the outline: [toOutline]
  CircleRegion(this.center, this.radius, {super.name}) : super();

  /// Center coordinate
  final LatLng center;

  /// Radius in kilometers
  final double radius;

  @override
  DownloadableRegion<CircleRegion> toDownloadable({
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
            points: toOutline().toList(),
            isFilled: fillColor != null,
            color: fillColor ?? Colors.transparent,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
            isDotted: isDotted,
            label: label,
            labelStyle: labelStyle,
            labelPlacement: labelPlacement,
          ),
        ],
      );

  @override
  Iterable<LatLng> toOutline() sync* {
    const dist = Distance(roundResult: false, calculator: Haversine());

    final radius = this.radius * 1000;

    for (int angle = -180; angle <= 180; angle++) {
      yield dist.offset(center, radius, angle);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CircleRegion &&
          other.center == center &&
          other.radius == radius &&
          super == other);

  @override
  int get hashCode => Object.hash(center, radius, super.hashCode);
}
