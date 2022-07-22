import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'downloadable_region.dart';

/// A region that can be downloaded, drawn on a map, or converted to a list of points, that forms a particular shape
abstract class BaseRegion {
  /// Create a downloadable region out of this region - for more information see [DownloadableRegion]'s properties' documentation
  ///
  /// Returns a [DownloadableRegion] to be passed to the `StorageCachingTileProvider().downloadRegion()`, `StorageCachingTileProvider().downloadRegionBackground()`, or `StorageCachingTileProvider().checkRegion()` function.
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    int parallelThreads = 10,
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    int start = 0,
    int? end,
    Crs crs = const Epsg3857(),
    void Function(Object?)? errorHandler,
  });

  /// Create a drawable area for a [FlutterMap] out of this region
  ///
  /// Returns a [PolygonLayerOptions] to be added to the `layer` property of a [FlutterMap].
  PolygonLayerOptions toDrawable({
    Color? fillColor,
    Color borderColor = const Color(0x00000000),
    double borderStrokeWidth = 3,
    bool isDotted = false,
  });

  /// Create a list of all the [LatLng]s along the outline of this region
  ///
  /// Not supported on line regions: use `toOutlines()` instead.
  ///
  /// Returns a `List<LatLng>` which can be used anywhere.
  List<LatLng> toList();
}
