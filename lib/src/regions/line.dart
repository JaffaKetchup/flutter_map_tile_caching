import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'downloadableRegion.dart';

/// A region with the border as the loci of a line at it's center
class LineRegion extends BaseRegion {
  /// A line defined by a list of`LatLng`s
  final List<LatLng> line;

  /// The offset of the border in each direction in meters, like a radius
  final double radius;

  /// Creates a region with the border as the loci of a line at it's center
  LineRegion(this.line, this.radius);

  /// Creates a list of rectangles made of the loci of the specified line which can be used anywhere
  ///
  /// Use the optional `overlap` argument to set the corner behavior. -1 is reduced, 0 is normal, 1 is full.
  List<List<LatLng>> toOutlines([int overlap = -1]) {
    assert(overlap >= -1 && overlap <= 1,
        '`overlap` must be between -1 and 1 inclusive');

    final Distance dist = Distance();
    final int rad = (radius * math.pi / 4).round();
    return line.map((pos) {
      if ((line.indexOf(pos) + 1) >= line.length) return [LatLng(0, 0)];

      final List<LatLng> section = [pos, line[line.indexOf(pos) + 1]];

      final double bearing = dist.bearing(section[0], section[1]);
      final double clockwiseRotation =
          (90 + bearing) > 360 ? 360 - (90 + bearing) : (90 + bearing);
      final double anticlockwiseRotation =
          (bearing - 90) < 0 ? 360 + (bearing - 90) : (bearing - 90);

      final LatLng offset1 =
          dist.offset(section[0], rad, clockwiseRotation); // Top-right
      final LatLng offset2 =
          dist.offset(section[1], rad, clockwiseRotation); // Bottom-right
      final LatLng offset3 =
          dist.offset(section[1], rad, anticlockwiseRotation); // Bottom-left
      final LatLng offset4 =
          dist.offset(section[0], rad, anticlockwiseRotation); // Top-right

      if (overlap == 0) return [offset1, offset2, offset3, offset4];

      final bool r = overlap == -1;
      final bool os = line.indexOf(pos) == 0;
      final bool oe = line.indexOf(pos) == line.length - 2;
      return [
        os ? offset1 : dist.offset(offset1, r ? rad : -rad, bearing),
        oe ? offset2 : dist.offset(offset2, r ? -rad : rad, bearing),
        oe ? offset3 : dist.offset(offset3, r ? -rad : rad, bearing),
        os ? offset4 : dist.offset(offset4, r ? rad : -rad, bearing),
      ];
    }).toList()
      ..removeLast();
  }

  @override
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    int parallelThreads = 10,
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    Function(dynamic)? errorHandler,
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  }) {
    return DownloadableRegion(
      toOutlines(1).expand((x) => x).toList(),
      minZoom,
      maxZoom,
      options,
      RegionType.line,
      this,
      parallelThreads: parallelThreads,
      preventRedownload: preventRedownload,
      seaTileRemoval: seaTileRemoval,
      crs: crs,
      errorHandler: errorHandler,
    );
  }

  /// Create a drawable area for `FlutterMap()` out of this region
  ///
  /// Use the optional `overlap` argument to set the corner behavior. -1 is reduced, 0 is normal, 1 is full.
  ///
  /// Returns a `PolygonLayerOptions` to be added to the layer property of a `FlutterMap()`.
  @override
  PolygonLayerOptions toDrawable(
    Color fillColor,
    Color borderColor, {
    double borderStrokeWidth = 3.0,
    bool isDotted = false,
    int overlap = -1,
  }) {
    final List<List<LatLng>> rects = toOutlines(overlap);

    return PolygonLayerOptions(
      polygons: rects
          .map(
            (e) => Polygon(
              color: fillColor,
              borderColor: borderColor,
              borderStrokeWidth: borderStrokeWidth,
              isDotted: isDotted,
              points: e,
            ),
          )
          .toList(),
    );
  }

  /// This method is unavailable for this region type: use `toOutlines()` instead
  @alwaysThrows
  @override
  List<LatLng> toList() {
    throw UnsupportedError(
        '`toList` is invalid for this region type: use `toOutlines()` instead');
  }
}
