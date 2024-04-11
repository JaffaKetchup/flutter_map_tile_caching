// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A downloadable region to be passed to bulk download functions
///
/// Construct via [BaseRegion.toDownloadable].
class DownloadableRegion<R extends BaseRegion> {
  DownloadableRegion._(
    this.originalRegion, {
    required this.minZoom,
    required this.maxZoom,
    required this.options,
    required this.start,
    required this.end,
    required this.crs,
  }) {
    if (minZoom > maxZoom) {
      throw ArgumentError(
        '`minZoom` must be less than or equal to `maxZoom`',
      );
    }
    if (start < 1 || start > (end ?? double.infinity)) {
      throw ArgumentError(
        '`start` must be greater or equal to 1 and less than or equal to `end`',
      );
    }
  }

  /// A copy of the [BaseRegion] used to form this object
  ///
  /// To make decisions based on the type of this region, prefer [when] over
  /// switching on [R] manually.
  final R originalRegion;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// The options used to fetch tiles
  final TileLayer options;

  /// Optionally skip any tiles before this tile
  ///
  /// The order of the tiles in a region is directly chosen by the underlying
  /// tile generators, and so may not be stable between updates.
  ///
  /// Set to 1 to skip none, which is the default.
  final int start;

  /// Optionally skip any tiles after this tile
  ///
  /// The order of the tiles in a region is directly chosen by the underlying
  /// tile generators, and so may not be stable between updates.
  ///
  /// Set to `null` to skip none, which is the default.
  final int? end;

  /// The map projection to use to calculate tiles. Defaults to [Epsg3857].
  final Crs crs;

  /// Cast [originalRegion] from [R] to [N]
  @optionalTypeArgs
  DownloadableRegion<N> _cast<N extends BaseRegion>() => DownloadableRegion._(
        originalRegion as N,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );

  /// Output a value of type [T] dependent on [originalRegion] and its type [R]
  T when<T>({
    required T Function(DownloadableRegion<RectangleRegion> rectangle)
        rectangle,
    required T Function(DownloadableRegion<CircleRegion> circle) circle,
    required T Function(DownloadableRegion<LineRegion> line) line,
    required T Function(DownloadableRegion<CustomPolygonRegion> customPolygon)
        customPolygon,
  }) =>
      switch (originalRegion) {
        RectangleRegion() => rectangle(_cast()),
        CircleRegion() => circle(_cast()),
        LineRegion() => line(_cast()),
        CustomPolygonRegion() => customPolygon(_cast()),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadableRegion &&
          other.originalRegion == originalRegion &&
          other.minZoom == minZoom &&
          other.maxZoom == maxZoom &&
          other.options == options &&
          other.start == start &&
          other.end == end &&
          other.crs == crs);

  @override
  int get hashCode => Object.hashAllUnordered([
        originalRegion,
        minZoom,
        maxZoom,
        options,
        start,
        end,
        crs,
      ]);
}
