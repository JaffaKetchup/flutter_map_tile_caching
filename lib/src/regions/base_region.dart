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

  /// Output a value of type [T] the type of this region
  ///
  /// Requires all region types to have a defined handler. See [maybeWhen] for
  /// the equivalent where this is not required.
  @Deprecated(
    'Prefer using a pattern matching selection (such as `if case` or '
    '`switch`). This will be removed in a future version.',
  )
  T when<T>({
    required T Function(RectangleRegion rectangle) rectangle,
    required T Function(CircleRegion circle) circle,
    required T Function(LineRegion line) line,
    required T Function(CustomPolygonRegion customPolygon) customPolygon,
    required T Function(MultiRegion multi) multi,
  }) =>
      maybeWhen(
        rectangle: rectangle,
        circle: circle,
        line: line,
        customPolygon: customPolygon,
        multi: multi,
      )!;

  /// Output a value of type [T] the type of this region
  ///
  /// If the specified method is not defined for the type of region which this
  /// region is, `null` will be returned.
  @Deprecated(
    'Prefer using a pattern matching selection (such as `if case` or '
    '`switch`). This will be removed in a future version.',
  )
  T? maybeWhen<T>({
    T Function(RectangleRegion rectangle)? rectangle,
    T Function(CircleRegion circle)? circle,
    T Function(LineRegion line)? line,
    T Function(CustomPolygonRegion customPolygon)? customPolygon,
    T Function(MultiRegion multi)? multi,
  }) =>
      switch (this) {
        RectangleRegion() => rectangle?.call(this as RectangleRegion),
        CircleRegion() => circle?.call(this as CircleRegion),
        LineRegion() => line?.call(this as LineRegion),
        CustomPolygonRegion() =>
          customPolygon?.call(this as CustomPolygonRegion),
        MultiRegion() => multi?.call(this as MultiRegion),
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
