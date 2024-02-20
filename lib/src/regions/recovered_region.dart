// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// A mixture between [BaseRegion] and [DownloadableRegion] containing all the
/// salvaged data from a recovered download
///
/// See [RootRecovery] for information about the recovery system.
///
/// The availability of [bounds], [line], [center] & [radius] depend on the
/// type [R] of the recovered region. Use [toDownloadable] to restore a valid
/// [DownloadableRegion].
class RecoveredRegion<R extends BaseRegion> {
  /// A unique ID created for every bulk download operation
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final int id;

  /// The store name originally associated with this download.
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final String storeName;

  /// The time at which this recovery was started
  ///
  /// Not actually used when converting to [DownloadableRegion].
  final DateTime time;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// Optionally skip past a number of tiles 'at the start' of a region
  final int start;

  /// Optionally skip a number of tiles 'at the end' of a region
  final int? end;

  /// The bounds for a rectangular region
  final LatLngBounds? bounds;

  /// The line making a line-based region or the outline making a custom polygon
  /// region
  final List<LatLng>? line;

  /// The center of a circular region
  final LatLng? center;

  /// The radius of a circular region
  final double? radius;

  @internal
  RecoveredRegion({
    required this.id,
    required this.storeName,
    required this.time,
    required this.minZoom,
    required this.maxZoom,
    required this.start,
    required this.end,
    required this.bounds,
    required this.center,
    required this.line,
    required this.radius,
  });

  /// Convert this region into a [BaseRegion]
  R toRegion() => switch (R) {
        RectangleRegion => RectangleRegion(bounds!),
        CircleRegion => CircleRegion(center!, radius!),
        LineRegion => LineRegion(this.line!, radius!),
        CustomPolygonRegion => CustomPolygonRegion(this.line!),
        _ => throw UnimplementedError(),
      } as R;

  /// Convert this region into a [DownloadableRegion]
  DownloadableRegion<R> toDownloadable(
    TileLayer options, {
    Crs crs = const Epsg3857(),
  }) =>
      DownloadableRegion._(
        toRegion(),
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );
}
