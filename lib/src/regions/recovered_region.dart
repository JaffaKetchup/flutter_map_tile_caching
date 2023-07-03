// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// A mixture between [BaseRegion] and [DownloadableRegion] containing all the
/// salvaged data from a recovered download
///
/// How does recovery work? At the start of a download, a file is created
/// including information about the download. At the end of a download or when a
/// download is correctly cancelled, this file is deleted. However, if there is
/// no ongoing download (controlled by an internal variable) and the recovery
/// file exists, the download has obviously been stopped incorrectly, meaning it
/// can be recovered using the information within the recovery file.
///
/// The availability of [bounds], [line], [center] & [radius] depend on the
/// [_type] of the recovered region.
///
/// Should avoid manual construction. Use [toDownloadable] to restore a valid
/// [DownloadableRegion].
class RecoveredRegion {
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

  final RegionType _type;

  /// The bounds for a rectangular region
  final LatLngBounds? bounds;

  /// The line making a line-based region
  final List<LatLng>? line;

  /// The center of a circular region
  final LatLng? center;

  /// The radius of a circular region
  final double? radius;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// Optionally skip past a number of tiles 'at the start' of a region
  final int start;

  /// Optionally skip a number of tiles 'at the end' of a region
  final int? end;

  RecoveredRegion._({
    required this.id,
    required this.storeName,
    required this.time,
    required RegionType type,
    required this.bounds,
    required this.center,
    required this.line,
    required this.radius,
    required this.minZoom,
    required this.maxZoom,
    required this.start,
    required this.end,
  }) : _type = type;

  /// Convert this region into it's original [BaseRegion], calling the respective
  /// callback with it
  T toRegion<T>({
    required T Function(RectangleRegion rectangle) rectangle,
    required T Function(CircleRegion circle) circle,
    required T Function(LineRegion line) line,
  }) =>
      switch (_type) {
        RegionType.rectangle => rectangle(RectangleRegion(bounds!)),
        RegionType.circle => circle(CircleRegion(center!, radius!)),
        RegionType.line => line(LineRegion(this.line!, radius!)),
      };

  /// Convert this region into a [DownloadableRegion]
  DownloadableRegion toDownloadable(
    TileLayer options, {
    Crs crs = const Epsg3857(),
    Function(Object?)? errorHandler,
  }) =>
      DownloadableRegion._(
        toRegion(rectangle: (r) => r, circle: (c) => c, line: (l) => l),
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );
}
