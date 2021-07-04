import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Describes what shape, and therefore rules, a `DownloadableRegion` conforms to
enum RegionType {
  /// A region containing 4 points representing each corner
  rectangle,

  /// A region containing all the points along it's outline (one every degree)
  circle,

  /// A region containing all the points along it's loci (one per side for every node)
  line,

  /// A region containing any number of points representing it's outline (one per vertice)
  customPolygon,
}

/// A region that can be downloaded, drawn on a map, or converted to a list of points, that forms a particular shape
abstract class BaseRegion {
  /// Create a downloadable region out of this region
  ///
  /// Returns a `DownloadableRegion` to be passed to the `StorageCachingTileProvider().downloadRegion()`, `StorageCachingTileProvider().downloadRegionBackground()`, or `StorageCachingTileProvider().checkRegion()` function.
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
  });

  /// Create a drawable area for `FlutterMap()` out of this region
  ///
  /// Returns a `PolygonLayerOptions` to be added to the `layer` property of a `FlutterMap()`.
  PolygonLayerOptions toDrawable(
    Color fillColor,
    Color borderColor, {
    double borderStrokeWidth = 3.0,
    bool isDotted = false,
  });

  /// Create a list of all the `LatLng`s along the outline of this region
  ///
  /// Returns a `List<LatLng>` which can be used anywhere.
  List<LatLng> toList();
}

/// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
///
/// Accuracy depends on the `RegionType`. All types except sqaure are calculated as if on a flat plane, so use should be avoided at the poles and the radius/allowance/distance should be no more than 10km. There is potential for more accurate calculations in the future.
///
/// Should avoid manual construction (hidden class). Use a supported region shape and the `.toDownloadable()` extension on it.
///
/// Is returned from `.toDownloadable()`.
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

  /// The map projection to use to calculate tiles. Defaults to `Espg3857()`.
  final Crs crs;

  /// The size of each tile. Defaults to 256 by 256.
  final CustomPoint<num> tileSize;

  /// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
  ///
  /// Accuracy depends on the `RegionType`. All types except sqaure are calculated as if on a flat plane, so use should be avoided at the poles and the radius/allowance/distance should be no more than 10km. There is potential for more accurate calculations in the future.
  ///
  /// Should avoid manual construction (hidden class). Use a supported region shape and the `.toDownloadable()` extension on it.
  ///
  /// Is returned from `.toDownloadable()`.
  DownloadableRegion(
    this.points,
    this.minZoom,
    this.maxZoom,
    this.options,
    this.type, {
    this.errorHandler,
    this.crs = const Epsg3857(),
    this.tileSize = const CustomPoint(256, 256),
  });
}

/// An object representing the progress of a download
///
/// Should avoid manual construction, use `DownloadProgress.placeholder()`.
///
/// Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder()`.
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
  /// Should avoid manual construction, use `DownloadProgress.placeholder()`.
  ///
  /// Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder()`.
  @internal
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
