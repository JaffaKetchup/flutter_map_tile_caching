// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

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
        '`minZoom` should be less than or equal to `maxZoom`',
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

  /// Optionally skip past a number of tiles 'at the start' of a region
  ///
  /// Set to 0 to skip none, which is the default.
  final int start;

  /// Optionally skip a number of tiles 'at the end' of a region
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
