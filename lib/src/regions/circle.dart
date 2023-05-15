// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

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
  CircleRegion(
    this.center,
    this.radius, {
    super.name,
  });

  /// Center coordinate
  final LatLng center;

  /// Radius in kilometers
  final double radius;

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
      DownloadableRegion._(
        this,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
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
            points: toOutline(),
          )
        ],
      );

  @override
  List<LatLng> toOutline() {
    final double rad = radius / 1.852 / 3437.670013352;
    final double lat = center.latitudeInRad;
    final double lon = center.longitudeInRad;
    final List<LatLng> output = [];

    for (int x = 0; x <= 360; x++) {
      final double brng = x * math.pi / 180;
      final double latRadians = math.asin(
        math.sin(lat) * math.cos(rad) +
            math.cos(lat) * math.sin(rad) * math.cos(brng),
      );
      final double lngRadians = lon +
          math.atan2(
            math.sin(brng) * math.sin(rad) * math.cos(lat),
            math.cos(rad) - math.sin(lat) * math.sin(latRadians),
          );

      output.add(
        LatLng(
          latRadians * 180 / math.pi,
          (lngRadians * 180 / math.pi)
              .clamp(-180, 180), // Clamped to fix errors with flutter_map
        ),
      );
    }

    return output;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CircleRegion &&
          other.center == center &&
          other.radius == radius &&
          super == other);

  @override
  int get hashCode => Object.hashAllUnordered([center, radius, super.hashCode]);
}
