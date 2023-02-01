// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

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
  RectangleRegion(
    this.bounds, {
    super.name,
  });

  /// The coordinate bounds
  final LatLngBounds bounds;

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
  List<LatLng> toOutline() => [
        LatLng(bounds.southEast.latitude, bounds.northWest.longitude),
        bounds.southEast,
        LatLng(bounds.northWest.latitude, bounds.southEast.longitude),
        bounds.northWest,
      ];
}
