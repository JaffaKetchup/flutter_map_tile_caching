// DOWNLOADING LINE FUNCTIONALITY IS HIGHLY EXPERIMENTAL & SHOULD NOT BE USED IN PRODUCTION
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import 'downloadableRegion.dart';

/// A region with the border as the loci of a line at it's center
class LineRegion extends BaseRegion {
  /// The line at the center as a list of`LatLng`s
  ///
  /// Only define this if `encodedPolyline` will be `null`. Must define at least one.
  final List<LatLng>? line;

  /// The line at the center as a Google format encoded polyline
  ///
  /// Example: _piFps|U_ulLnnqC_mqNvxq`@
  ///
  /// Only define this if `line` will be `null`. Must define at least one.
  final String? encodedPolyline;

  /// The offset of the border in each direction in meters, like a radius
  final double radius;

  /// Creates a region with the border as the loci of a line at it's center
  LineRegion({this.line, this.encodedPolyline, required this.radius});

  List<LatLng> _getSafeLine() {
    if (line == null || line!.length < 2) {
      assert(encodedPolyline != null,
          'Must define either `line` or `encodedPolyline`');
      return toList();
    }
    if (encodedPolyline == null) {
      assert(line != null && line!.length > 1,
          'Must define either `line` or `encodedPolyline`');
      return line!;
    }
    assert(!((line == null || line!.length < 2) && encodedPolyline == null),
        'Must define either `line` or `encodedPolyline`');
    throw UnimplementedError();
  }

  /// Creates a list of rectangles made of the loci of the specified line which can be used anywhere
  ///
  /// Use the optional `overlap` argument to set the corner behavior. -1 is reduced, 0 is normal, 1 is full.
  ///
  /// To convert an encoded polyline to a list of `LatLng`s, use `toList()` instead.
  List<List<LatLng>> toRealList([int overlap = -1]) {
    assert(overlap >= -1 && overlap <= 1,
        '`overlap` must be between -1 and 1 inclusive');

    final Distance dist = Distance();
    final int rad = (radius * math.pi / 4).round();
    final List<LatLng> points = _getSafeLine();

    return points.map((e) {
      if ((points.indexOf(e) + 1) >= points.length) return [LatLng(0, 0)];

      final List<LatLng> line = [e, points[points.indexOf(e) + 1]];

      final double bearing = dist.bearing(line[0], line[1]);
      final double clockwiseRotation =
          (90 + bearing) > 360 ? 360 - (90 + bearing) : (90 + bearing);
      final double anticlockwiseRotation =
          (bearing - 90) < 0 ? 360 + (bearing - 90) : (bearing - 90);

      final LatLng offset1 =
          dist.offset(line[0], rad, clockwiseRotation); // Top-right
      final LatLng offset2 =
          dist.offset(line[1], rad, clockwiseRotation); // Bottom-right
      final LatLng offset3 =
          dist.offset(line[1], rad, anticlockwiseRotation); // Bottom-left
      final LatLng offset4 =
          dist.offset(line[0], rad, anticlockwiseRotation); // Top-right

      if (overlap == 0) return [offset1, offset2, offset3, offset4];

      final bool r = overlap == -1;
      final bool os = points.indexOf(e) == 0;
      final bool oe = points.indexOf(e) == points.length - 2;
      return [
        os ? offset1 : dist.offset(offset1, r ? rad : -rad, bearing),
        oe ? offset2 : dist.offset(offset2, r ? -rad : rad, bearing),
        oe ? offset3 : dist.offset(offset3, r ? -rad : rad, bearing),
        os ? offset4 : dist.offset(offset4, r ? rad : -rad, bearing),
      ];
    }).toList();
  }

  /// Downloading lines is highly experimental and has a high chance of failing and causing errors
  ///
  /// You should not use this functionality unless absolutley necessary. Note that this functonality is liable to change at any time in the future without a breaking change version bump.
  @override
  @experimental
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    bool preventRedownload = false,
    Color? seaColor,
    int compressionQuality = -1,
    Function(dynamic)? errorHandler,
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  }) {
    return DownloadableRegion(
      toRealList(1).expand((x) => x).toList(),
      minZoom,
      maxZoom,
      options,
      RegionType.line,
      errorHandler: errorHandler,
      crs: crs,
      //splitIndex: 4,
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
    final List<List<LatLng>> rects = toRealList(overlap);

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

  /// Convert an encoded polyline to a list of `LatLng`s
  ///
  /// To get a list of rectangles made of the loci of the specified line, use `toRealList()` instead.
  @override
  List<LatLng> toList() {
    assert(encodedPolyline != null && line == null,
        'To convert to a list of points, only `encodedPolyline` can be defined\nIf you\'re looking to get a list of rectangles made of the loci of the specified line, use `toRealList()` instead.');

    return PolylinePoints()
        .decodePolyline(encodedPolyline!)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }
}
