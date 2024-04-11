// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A mixture between [BaseRegion] and [DownloadableRegion] containing all the
/// salvaged data from a recovered download
///
/// See [RootRecovery] for information about the recovery system.
///
/// The availability of [bounds], [line], [center] & [radius] depend on the
/// represented type of the recovered region. Use [toDownloadable] to restore a
/// valid [DownloadableRegion].
class RecoveredRegion {
  /// A mixture between [BaseRegion] and [DownloadableRegion] containing all the
  /// salvaged data from a recovered download
  ///
  /// See [RootRecovery] for information about the recovery system.
  ///
  /// The availability of [bounds], [line], [center] & [radius] depend on the
  /// represented type of the recovered region. Use [toDownloadable] to restore
  /// a valid [DownloadableRegion].
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

  /// A unique ID created for every bulk download operation
  final int id;

  /// The store name originally associated with this download
  final String storeName;

  /// The time at which this recovery was started
  final DateTime time;

  /// Corresponds to [DownloadableRegion.minZoom]
  final int minZoom;

  /// Corresponds to [DownloadableRegion.maxZoom]
  final int maxZoom;

  /// Corresponds to [DownloadableRegion.start]
  ///
  /// May not match as originally created, may be the last successful tile. The
  /// interval between [start] and [end] is the failed interval.
  final int start;

  /// Corresponds to [DownloadableRegion.end]
  ///
  /// If originally created as `null`, this will be the number of tiles in the
  /// region, as determined by [StoreDownload.check].
  final int end;

  /// Corresponds to [RectangleRegion.bounds]
  final LatLngBounds? bounds;

  /// Corrresponds to [LineRegion.line] & [CustomPolygonRegion.outline]
  final List<LatLng>? line;

  /// Corrresponds to [CircleRegion.center]
  final LatLng? center;

  /// Corrresponds to [LineRegion.radius] & [CircleRegion.radius]
  final double? radius;

  /// Convert this region into a [BaseRegion]
  ///
  /// Determine which type of [BaseRegion] using [BaseRegion.when].
  BaseRegion toRegion() {
    if (bounds != null) return RectangleRegion(bounds!);
    if (center != null) return CircleRegion(center!, radius!);
    if (line != null && radius != null) return LineRegion(line!, radius!);
    return CustomPolygonRegion(line!);
  }

  /// Convert this region into a [DownloadableRegion]
  DownloadableRegion toDownloadable(
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
