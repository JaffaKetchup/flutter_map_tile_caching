// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A wrapper containing recovery & some downloadable region information, around
/// a [DownloadableRegion]
///
/// See [RootRecovery] for information about the recovery system.
class RecoveredRegion<R extends BaseRegion> {
  /// Create a wrapper containing recovery information around a
  /// [DownloadableRegion]
  @internal
  RecoveredRegion({
    required this.id,
    required this.storeName,
    required this.time,
    required this.minZoom,
    required this.maxZoom,
    required this.start,
    required this.end,
    required this.region,
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

  /// The [BaseRegion] which was recovered
  final R region;

  /// Convert this region into a [DownloadableRegion]
  DownloadableRegion toDownloadable(
    TileLayer options, {
    Crs crs = const Epsg3857(),
  }) =>
      DownloadableRegion._(
        region,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );
}
