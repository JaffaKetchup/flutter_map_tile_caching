import 'package:flutter_map/plugin_api.dart' show TileLayerOptions;
import 'package:latlong2/latlong.dart';

/// Describes what shape, and therefore rules, a `DownloadableRegion` conforms to.
enum RegionType {
  /// A region containing 4 points representing each corner
  rectangle,

  /// A region containing all the points along it's outline (one every degree)
  circle,

  /// A region containing all the points along it's outline (one per side every node)
  line,

  /// A region containing any number of points representing it's outline (one per vertice)
  customPolygon,
}

/// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
///
/// Accuracy depends on the `RegionType`. All types except sqaure are calculated as if on a flat plane, so use should be avoided at the poles and the radius/allowance/distance should be no more than 10km. There is potential for more accurate calculations in the future.
///
/// Should avoid manual construction (hidden class). Use a supported region shape and the `.toDownloadable()` extension on it. Is returned from `.toDownloadable()`.
class DownloadableRegion {
  /// All the verticies on the outline of a polygon
  final List<LatLng> points;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// The shape that this region conforms to
  final RegionType type;

  /// The options used to fetch tiles
  final TileLayerOptions options;

  /// A function that takes any type of error as an argument to be called in the event a tile fetch fails
  final Function(dynamic)? errorHandler;

  /// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
  ///
  /// Accuracy depends on the `RegionType`. All types except sqaure are calculated as if on a flat plane, so use should be avoided at the poles and the radius/allowance/distance should be no more than 10km. There is potential for more accurate calculations in the future.
  ///
  /// Should avoid manual construction (hidden class). Use a supported region shape and the `.toDownloadable()` extension on it. Is returned from `.toDownloadable()`.
  DownloadableRegion(
    this.points,
    this.minZoom,
    this.maxZoom,
    this.options,
    this.type, [
    this.errorHandler,
  ]);
}

/// An object representing the progress of a download
///
/// Should avoid manual construction, use `DownloadProgress.placeholder()`. Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder()`.
class DownloadProgress {
  /// Number of attempted tile downloads (includes failures)
  final int completedTiles;

  /// Total number of tiles to be downloaded
  final int totalTiles;

  /// All the URLs which failed to fetch for any reason
  final List<String> erroredTiles;

  /// The percentage that the download has completed, including failures
  final double percentageProgress;

  /// An object representing the progress of a download
  ///
  /// Should avoid manual construction, use `DownloadProgress.placeholder()`. Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder()`.
  DownloadProgress(
    this.completedTiles,
    this.totalTiles,
    this.erroredTiles,
    this.percentageProgress,
  );

  /// Create a placeholder (all values set to 0) `DownloadProgress`, useful for `initalData` in a `StreamBuilder()`
  static DownloadProgress placeholder() {
    return DownloadProgress(0, 0, [], 0);
  }
}
