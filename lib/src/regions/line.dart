import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

import 'downloadableRegion.dart';
import 'diagonalRectangle.dart';

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

  @override
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
    double resolution = 10,
    void Function(List<List<LatLng>>, int)? tmp,
  }) {
    final Distance dist = Distance();
    final int res = (resolution * math.pi / 4).round();

    final List<List<LatLng>> rects = toRealList(1);
    final List<List<LatLng>> resRects = rects.map((rect) {
      if (rect.length == 1) return rect;
      final double bearing1 = dist.bearing(rect[0], rect[1]);
      final double distance1 = dist.distance(rect[0], rect[1]);

      final double bearing2 = dist.bearing(rect[1], rect[2]);
      final double distance2 = dist.distance(rect[1], rect[2]);

      final double bearing3 = dist.bearing(rect[2], rect[3]);
      final double distance3 = dist.distance(rect[2], rect[3]);

      final double bearing4 = dist.bearing(rect[3], rect[0]);
      final double distance4 = dist.distance(rect[3], rect[0]);

      final List<LatLng> returnable = [];

      double i = 0;
      while (i < distance1 / res) {
        returnable.add(dist.offset(rect[0], res, bearing1));
        i = i + res;
      }

      i = 0;
      while (i < distance2 / res) {
        returnable.add(dist.offset(rect[1], res, bearing2));
        i = i + res;
      }

      i = 0;
      while (i < distance3 / res) {
        returnable.add(dist.offset(rect[2], res, bearing3));
        i = i + res;
      }

      i = 0;
      while (i < distance4 / res) {
        returnable.add(dist.offset(rect[3], res, bearing4));
        i = i + res;
      }

      return returnable;
    }).toList();

    final List<LatLng> flattened = resRects.expand((x) => x).toList();

    tmp!(resRects, rects.length ~/ flattened.length);

    return DownloadableRegion(
      flattened,
      minZoom,
      maxZoom,
      options,
      RegionType.line,
      errorHandler: errorHandler,
      crs: crs,
      tileSize: tileSize,
      splitIndex: rects.length ~/ flattened.length,
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
