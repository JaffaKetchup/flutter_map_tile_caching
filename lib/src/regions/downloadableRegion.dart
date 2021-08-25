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

  /// Depreciated due to lack of associated functionality. Remove all references throughout your code.
  @Deprecated(
    'This value has been deprecated, because there was no associated functionality. Remove all references throughout your code.',
  )
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
    bool preventRedownload = false,
    Color? seaColor,
    int compressionQuality = -1,
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
  /// Returns a `List<LatLng>` which can be used anywhere.
  List<LatLng> toList();
}

/// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
///
/// Should avoid manual construction. Use a supported region shape and the `.toDownloadable()` extension on it.
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

  /// Whether to skip downloading tiles that already exist. Defaults to `false`, so that existing tiles will be updated.
  final bool preventRedownload;

  /// Color of the sea in tiles from your source to remove sea tiles with
  ///
  /// Note that enabling sea tile removal severely lengthens download time, but decreases storage used. Tiles still have to be fully downloaded before they can be checked.
  ///
  /// Set to `null` to keep sea tiles, which is the default.
  final Color? seaColor;

  /// The compression level percentage from 1 (bad quality) to 99 (good quality) to compress tiles with
  ///
  /// Note that enabling compression severely lengthens download time, but decreases storage used.
  ///
  /// Set to -1 to disable compression, which is the default.
  final int compressionQuality;

  /// The map projection to use to calculate tiles. Defaults to `Espg3857()`.
  final Crs crs;

  /// A function that takes any type of error as an argument to be called in the event a tile fetch fails or a tile already exists and `preventRedownload` is `true`
  ///
  /// If the handler is called for the second reason above, the argument will be a String equalling "exists"; otherwise it will be a String with the URL of the failed tile.
  final Function(dynamic)? errorHandler;

  /// Deprecated. Will be removed in next release. Migrate to the equivalent in the `TileLayerOptions`.
  ///
  /// The size of each tile. Defaults to 256 by 256.
  @Deprecated(
    'This paramter has been deprectated and will be removed in next release. Migrate to the equivalent in the `TileLayerOptions`.',
  )
  final CustomPoint<num> tileSize = CustomPoint(256, 256);

  /// A downloadable region to be passed to the `StorageCachingTileProvider().downloadRegion()` function
  ///
  /// Should avoid manual construction. Use a supported region shape and the `.toDownloadable()` extension on it.
  ///
  /// Is returned from `.toDownloadable()`.
  @internal
  DownloadableRegion(
    this.points,
    this.minZoom,
    this.maxZoom,
    this.options,
    this.type, {
    this.preventRedownload = false,
    this.seaColor,
    this.compressionQuality = -1,
    this.crs = const Epsg3857(),
    this.errorHandler,
  })  : assert(
          compressionQuality == -1 ||
              (compressionQuality >= 1 && compressionQuality <= 99),
          '`compressionQuality` must be -1 to signify that compression is disabled, or between 1 and 99 inclusive, representing the compression level percentage where 1 is bad quality and 99 is good quality',
        ),
        assert(
          minZoom <= maxZoom,
          '`minZoom` should be less than `maxZoom`',
        );
}

/// An object representing the progress of a download
///
/// Should avoid manual construction, use `DownloadProgress.placeholder`.
///
/// Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder`.
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
  /// Should avoid manual construction, use `DownloadProgress.placeholder`.
  ///
  /// Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder`.
  @internal
  DownloadProgress(
    this.completedTiles,
    this.totalTiles,
    this.erroredTiles,
    this.percentageProgress,
  );

  /// Create a placeholder (all values set to 0) `DownloadProgress`, useful for `initalData` in a `StreamBuilder()`
  static DownloadProgress get placeholder {
    return DownloadProgress(0, 0, [], 0);
  }
}
