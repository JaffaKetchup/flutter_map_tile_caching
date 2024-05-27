// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A geographical region that forms a particular shape
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - list of [LatLng]s forming the outline: [toOutline]
///
/// Extended/implemented by:
///  - [RectangleRegion]
///  - [CircleRegion]
///  - [LineRegion]
///  - [CustomPolygonRegion]
@immutable
sealed class BaseRegion {
  /// Create a geographical region that forms a particular shape
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - list of [LatLng]s forming the outline: [toOutline]
  ///
  /// Extended/implemented by:
  ///  - [RectangleRegion]
  ///  - [CircleRegion]
  ///  - [LineRegion]
  ///  - [CustomPolygonRegion]
  const BaseRegion();

  /// Output a value of type [T] dependent on `this` and its type
  T when<T>({
    required T Function(RectangleRegion rectangle) rectangle,
    required T Function(CircleRegion circle) circle,
    required T Function(LineRegion line) line,
    required T Function(CustomPolygonRegion customPolygon) customPolygon,
  }) =>
      switch (this) {
        RectangleRegion() => rectangle(this as RectangleRegion),
        CircleRegion() => circle(this as CircleRegion),
        LineRegion() => line(this as LineRegion),
        CustomPolygonRegion() => customPolygon(this as CustomPolygonRegion),
      };

  /// Generate the [DownloadableRegion] ready for bulk downloading
  ///
  /// For more information see [DownloadableRegion]'s documentation.
  DownloadableRegion toDownloadable({
    required int minZoom,
    required int maxZoom,
    required TileLayer options,
    int start = 1,
    int? end,
    Crs crs = const Epsg3857(),
  });

  /// Generate a graphical layer to be placed in a [FlutterMap]
  ///
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
  Widget toDrawable({
    Color? fillColor,
    Color borderColor = const Color(0x00000000),
    double borderStrokeWidth = 3,
    bool isDotted = false,
  });

  /// Generate the list of all the [LatLng]s forming the outline of this region
  ///
  /// Returns a `Iterable<LatLng>` which can be used anywhere.
  Iterable<LatLng> toOutline();

  @override
  @mustBeOverridden
  bool operator ==(Object other);

  @override
  @mustBeOverridden
  int get hashCode;
}
