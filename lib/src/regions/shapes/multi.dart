// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../../../flutter_map_tile_caching.dart';

/// A region formed from multiple other [BaseRegion]s
///
/// When downloading, each sub-region specified in [regions] is downloaded
/// consecutively. The advantage of [MultiRegion] is that:
///
///  * it avoids repeating the expensive setup and teardown of a bulk download
///    between each sub-region
///  * the progress of the download is reported as a whole, so no additional
///    work is required to keep track of which download is currently being
///    performed and keep track of custom progress statistics
///
/// Overlaps and intersections are not (yet) compiled into single
/// [CustomPolygonRegion]s. Therefore, where regions are known to overlap:
///
///  * (particularly where regions are [RectangleRegion]s & [CustomPolygonRegion]s)
///    Use ['package:polybool'](https://pub.dev/packages/polybool) (a 3rd party
///    package in no way associated with FMTC) to take the `union` all polygons:
///    this will remove self-intersections, combine overlapping polygons into
///    single polygons, etc - this is best for efficiency.
///
///  * (particularly where multiple different other region types are used)
///    Enable `skipExistingTiles` in [StoreDownload.startForeground].
///
/// [MultiRegion]s may be nested.
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
