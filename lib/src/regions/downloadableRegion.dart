import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Describes what shape, and therefore rules, a `DownloadableRegion` conforms to
enum RegionType {
  /// A region containing 2 points representing the top-left and bottom-right corners of a rectangle
  rectangle,

  /// A region containing all the points along it's outline (one every degree) representing a circle
  circle,

  /// A region with the border as the loci of a line at it's center representing multiple diagonal rectangles
  line,
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
    bool preventRedownload = false,
    bool seaTileRemoval,
    Crs crs = const Epsg3857(),
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
  /// Not supported on line regions: use `toOutlines()` instead.
  ///
  /// Returns a `List<LatLng>` which can be used anywhere.
  List<LatLng> toList();
}

/// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
///
/// Should avoid manual construction. Use a supported region shape and the `.toDownloadable()` extension on it.
///
/// Is returned from `.toDownloadable()`.
class DownloadableRegion {
  /// The shape that this region conforms to
  final RegionType type;

  /// The original `BaseRegion`, used internally for recovery purposes
  final BaseRegion originalRegion;

  /// All the verticies on the outline of a polygon
  final List<LatLng> points;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// The options used to fetch tiles
  final TileLayerOptions options;

  /// The number of download threads allowed to run simultaneously
  ///
  /// This will significatly increase speed, at the expense of faster battery drain. Note that some servers may forbid multithreading, in which case this should be set to 1.
  ///
  /// Set to 1 to disable multithreading (download will still be run in seperate isolate). Defaults to 10.
  final int parallelThreads;

  /// Whether to skip downloading tiles that already exist
  ///
  /// Defaults to `false`, so that existing tiles will be updated.
  final bool preventRedownload;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0, and z:19 to the bytes of the currently downloading tile. If they match, the tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satelite tiles (because of the variations from tile to tile), on maps where the tile 0/0/19 is not entirely sea, or on servers where zoom level 19 is not supported. If not supported, set this to `false` to avoid wasting unnecessary time and to avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be checked.
  ///
  /// Set to `false` to keep sea tiles, which is the default.
  final bool seaTileRemoval;

  /// The map projection to use to calculate tiles. Defaults to `Espg3857()`.
  final Crs crs;

  /// A function that takes any type of error as an argument to be called in the event a tile fetch fails
  final Function(dynamic)? errorHandler;

  /// Deprecated. Will be removed in next release. Migrate to the equivalent in the `TileLayerOptions`.
  ///
  /// The size of each tile. Defaults to 256 by 256.
  @Deprecated(
    'This paramter has been deprectated and will be removed in next release. Migrate to the equivalent in the `TileLayerOptions`.',
  )
  final CustomPoint<num> tileSize = CustomPoint(256, 256);

  @internal
  DownloadableRegion(
    this.points,
    this.minZoom,
    this.maxZoom,
    this.options,
    this.type,
    this.originalRegion, {
    this.parallelThreads = 10,
    this.preventRedownload = false,
    this.seaTileRemoval = false,
    this.crs = const Epsg3857(),
    this.errorHandler,
  })  : assert(
          minZoom <= maxZoom,
          '`minZoom` should be less than or equal to `maxZoom`',
        ),
        assert(
          parallelThreads >= 1,
          '`parallelThreads` should be more than or equal to 1. Set to 1 to disable multithreading',
        );
}
