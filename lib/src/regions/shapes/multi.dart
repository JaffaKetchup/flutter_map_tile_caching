// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../../flutter_map_tile_caching.dart';

/// A region formed from multiple other [BaseRegion]s
///
/// When downloading, each sub-region specified in [regions] is downloaded
/// consecutively. [MultiRegion]s may be nested.
///
/// [toOutline] is not supported and will always throw.
class MultiRegion extends BaseRegion {
  /// Create a region formed from multiple other [BaseRegion]s
  const MultiRegion(this.regions);

  /// List of sub-regions
  final List<BaseRegion> regions;

  @override
  DownloadableRegion<MultiRegion> toDownloadable({
    required int minZoom,
    required int maxZoom,
    required TileLayer options,
    int start = 1,
    int? end,
    Crs crs = const Epsg3857(),
  }) =>
      DownloadableRegion._(
        this,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );

  /// [MultiRegion]s do not support [toOutline], as it would not be useful,
  /// and it is out of scope to implement a convex-hull for no real purpose
  ///
  /// Instead, use [BaseRegion.toOutline] on each individual sub-region in
  /// [regions].
  @override
  Never toOutline() =>
      throw UnsupportedError('`MultiRegion`s do not support `toOutline`');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MultiRegion && listEquals(regions, other.regions));

  @override
  int get hashCode => Object.hashAll(regions);
}
