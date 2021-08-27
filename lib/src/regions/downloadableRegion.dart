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
    bool seaTileRemoval,
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

  /// The compression level percentage from 1 (bad quality) to 99 (good quality) to compress tiles with
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be compressed. Note that this will severely lengthen download time.
  ///
  /// Set to -1 to disable compression, which is the default.
  final int compressionQuality;

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
    this.seaTileRemoval = false,
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
  /// Number of successful tile downloads
  final int successfulTiles;

  /// List of URLs of failed tiles
  final List<String> failedTiles;

  /// Approximate total number of tiles to be downloaded
  final int maxTiles;

  /// Number of tiles removed because they were entirely sea (these also make up part of `successfulTiles`)
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is always 0.
  final int seaTiles;

  /// Number of tiles not downloaded because they already existed (these also make up part of `successfulTiles`)
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value is always 0.
  final int existingTiles;

  /// Duration since start of download process
  final Duration duration;

  /// Number of attempted tile downloads, including failures
  ///
  /// Is equal to `successfulTiles + failedTiles.length`.
  int get attemptedTiles => successfulTiles + failedTiles.length;

  /// Approximate number of tiles remaining to be downloaded
  ///
  /// Is equal to `approxMaxTiles - attemptedTiles`.
  int get remainingTiles => maxTiles - attemptedTiles;

  /// Percentage of tiles saved by using sea tile removal (ie. discount)
  ///
  /// Only applicable if sea tile removal is enabled, otherwise this value is always 0.
  ///
  /// Is equal to `100 - ((((successfulTiles - existingTiles) - seaTiles) / successfulTiles) * 100)`.
  double get seaTilesDiscount => seaTiles == 0
      ? 0
      : 100 -
          ((((successfulTiles - existingTiles) - seaTiles) / successfulTiles) *
              100);

  /// Percentage of tiles saved by using redownload prevention (ie. discount)
  ///
  /// Only applicable if redownload prevention is enabled, otherwise this value is always 0.
  ///
  /// Is equal to `100 -  ((((successfulTiles - seaTiles) - existingTiles) / successfulTiles) * 100)`.
  double get existingTilesDiscount => existingTiles == 0
      ? 0
      : 100 -
          ((((successfulTiles - seaTiles) - existingTiles) / successfulTiles) *
              100);

  /// Approximate percentage of process complete
  ///
  /// Is equal to `(attemptedTiles / approxMaxTiles) * 100`.
  double get percentageProgress => (attemptedTiles / maxTiles) * 100;

  /// Average duration (rounded) each tile has taken to either be removed (sea tile removal and redownload prevention) successfully download or fail
  ///
  /// Is equal to `Duration(milliseconds: (duration.inMilliseconds / attemptedTiles).round())`.
  Duration get avgDurationTile => Duration(
      milliseconds: (duration.inMilliseconds / attemptedTiles).round());

  /// Estimated duration for the whole download process based on `avgDurationTile`
  ///
  /// Is equal to `avgDurationTile * maxTiles`.
  Duration get estTotalDuration => avgDurationTile * maxTiles;

  /// Estimated remaining duration until the end of the download process, based on `estTotalDuration`
  ///
  /// Is equal to `estTotalDuration - duration`
  Duration get estRemainingDuration => estTotalDuration - duration;

  /// Deprecated due to internal refactoring. Migrate to `attemptedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.
  @Deprecated(
      'Deprecated due to internal refactoring. Migrate to `attemptedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.')
  int get completedTiles => attemptedTiles;

  /// Deprecated due to internal refactoring. Migrate to `failedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.
  @Deprecated(
      'Deprecated due to internal refactoring. Migrate to `failedTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.')
  List<String> get erroredTiles => failedTiles;

  /// Deprecated due to internal refactoring. Migrate to `maxTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.
  @Deprecated(
      'Deprecated due to internal refactoring. Migrate to `maxTiles` for nearest equivalent. Note that the new alternative is not exactly the same as this: read new documentation for information.')
  int get totalTiles => maxTiles;

  /// An object representing the progress of a download
  ///
  /// Should avoid manual construction, use `DownloadProgress.placeholder`.
  ///
  /// Is yielded from `StorageCachingTileProvider().downloadRegion()`, or returned from `DownloadProgress.placeholder`.
  @internal
  DownloadProgress({
    required this.successfulTiles,
    required this.failedTiles,
    required this.maxTiles,
    required this.seaTiles,
    required this.existingTiles,
    required this.duration,
  });

  /// Create a placeholder (all values set to 0) `DownloadProgress`, useful for `initalData` in a `StreamBuilder()`
  static DownloadProgress get placeholder => DownloadProgress(
        successfulTiles: 0,
        failedTiles: [],
        maxTiles: 0,
        seaTiles: 0,
        existingTiles: 0,
        duration: Duration(seconds: 0),
      );
}
