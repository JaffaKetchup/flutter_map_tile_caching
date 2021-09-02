import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'circle.dart';
import 'downloadableRegion.dart';
import 'line.dart';
import 'rectangle.dart';

/// A mixture between `BaseRegion` and `DownloadableRegion` containing all the salvaged data from a recovered download
///
/// `bounds` may be `null` if `type` is `RegionType.circle`. `center` and `radius` may be `null` if `type` is `RegionType.rectangle`. `preventRedownload` will always be `true`, as this is the functionality required to resume the failed download.
///
/// Should avoid manual construction. Use `.toDownloadable()` to restore a `DownloadableRegion`.
class RecoveredRegion {
  /// The shape that this region conforms to
  final RegionType type;

  /// The bounds for a rectangular region
  final LatLngBounds? bounds;

  /// The center of a circular region
  final LatLng? center;

  /// The radius of a circular region
  final double? radius;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// Whether to skip downloading tiles that already exist
  final bool preventRedownload = true;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0, and z:19 to the bytes of the currently downloading tile. If they match, the tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satelite tiles (because of the variations from tile to tile), on maps where the tile 0/0/19 is not entirely sea, or on servers where zoom level 19 is not supported. If not supported, set this to `false` to avoid wasting unnecessary time and to avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be checked.
  final bool seaTileRemoval;

  /// The compression level percentage from 1 (bad quality) to 99 (good quality) to compress tiles with
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be compressed. Note that this will severely lengthen download time.
  final int compressionQuality;

  @internal
  RecoveredRegion(
    this.type,
    this.bounds,
    this.center,
    this.radius,
    this.minZoom,
    this.maxZoom,
    this.seaTileRemoval,
    this.compressionQuality,
  );

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
        compressionQuality: compressionQuality,
        crs: crs,
        errorHandler: errorHandler,
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
        compressionQuality: compressionQuality,
        crs: crs,
        errorHandler: errorHandler,
      );
    else
      throw UnimplementedError(
        'This functionality is not yet supported, as the main part is experimental and this part has not been completed yet',
      );
  }
}
