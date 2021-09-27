import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'circle.dart';
import 'downloadableRegion.dart';
//import 'line.dart';
import 'line.dart';
import 'rectangle.dart';

/// A mixture between `BaseRegion` and `DownloadableRegion` containing all the salvaged data from a recovered download
///
/// How does recovery work? At the start of a download, a file is created including information about the download. At the end of a download or when a download is correctly cancelled, this file is deleted. However, if there is no ongoing download (controlled by an internal variable) and the recovery file exists, the download has obviously been stopped incorrectly, meaning it can be recovered using the information within the recovery file. If specific recovery was enabled, this download can be resumed from the last known tile number (stored alongside the recovery file), otherwise the download must start from the beginning.
///
/// The availability of `bounds`, `line`, `center` & `radius` depend on the `type` of the recovered region.
///
/// Should avoid manual construction. Use `.toDownloadable()` to restore a `DownloadableRegion`.
class RecoveredRegion {
  /// The shape that this region conforms to
  final RegionType type;

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

  /// Whether to skip downloading tiles that already exist
  final bool preventRedownload;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0, and z:19 to the bytes of the currently downloading tile. If they match, the tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satelite tiles (because of the variations from tile to tile), on maps where the tile 0/0/19 is not entirely sea, or on servers where zoom level 19 is not supported. If not supported, set this to `false` to avoid wasting unnecessary time and to avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be checked.
  final bool seaTileRemoval;

  /// If precise recovery was enabled, this contains the last known tile number
  final int? preciseRecovery;

  @internal
  RecoveredRegion(
    this.type,
    this.bounds,
    this.center,
    this.line,
    this.radius,
    this.minZoom,
    this.maxZoom,
    this.preventRedownload,
    this.seaTileRemoval, [
    this.preciseRecovery,
  ]);

  DownloadableRegion toDownloadable(
    TileLayerOptions options, {
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
  }) {
    if (type == RegionType.rectangle)
      return DownloadableRegion(
        [bounds!.northWest, bounds!.southEast],
        minZoom,
        maxZoom,
        options,
        type,
        RectangleRegion(bounds!),
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        crs: crs,
        errorHandler: errorHandler,
        resumeTile: preciseRecovery,
      );
    else if (type == RegionType.circle)
      return DownloadableRegion(
        CircleRegion(center!, radius!).toList(),
        minZoom,
        maxZoom,
        options,
        type,
        CircleRegion(center!, radius!),
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        crs: crs,
        errorHandler: errorHandler,
        resumeTile: preciseRecovery,
      );
    else
      return DownloadableRegion(
        LineRegion(line!, radius!).toList(),
        minZoom,
        maxZoom,
        options,
        type,
        CircleRegion(center!, radius!),
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        crs: crs,
        errorHandler: errorHandler,
        resumeTile: preciseRecovery,
      );
  }
}
