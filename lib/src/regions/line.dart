import 'dart:math' as math;

import 'package:bezier/bezier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart';

import 'downloadable_region.dart';

/// A region with the border as the locus of a line at it's center
class LineRegion implements BaseRegion {
  /// A line defined by a list of`LatLng`s
  final List<LatLng> line;

  /// The offset of the border in each direction in meters, like a radius
  final double radius;

  /// Creates a region with the border as the locus of a line at it's center
  LineRegion(this.line, this.radius);

  /// Creates a list of rectangles made of the locus of the specified line which can be used anywhere
  ///
  /// Use the optional `overlap` argument to set the rectangle joint(s) behaviours. -1 is reduced, 0 is normal (default), 1 is full (as downloaded).
  List<List<LatLng>> toOutlines([int overlap = 0]) {
    if (overlap >= -1 && overlap <= 1) {
      throw ArgumentError('`overlap` must be between -1 and 1 inclusive');
    }

    const Distance dist = Distance();
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
          dist.offset(section[0], rad, anticlockwiseRotation); // Top-left

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
    int start = 0,
    int? end,
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
  }) =>
      DownloadableRegion.internal(
        points: toOutlines(1).expand((x) => x).toList(),
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        type: RegionType.line,
        originalRegion: this,
        parallelThreads: parallelThreads,
        preventRedownload: preventRedownload,
        seaTileRemoval: seaTileRemoval,
        start: start,
        end: end,
        crs: crs,
        errorHandler: errorHandler,
      );

  /// Create a drawable area for a [FlutterMap] out of this region
  ///
  /// Configurable options besides those available normally in [Polygon] :
  ///  - [prettyPaint] - controls whether the rectangles formed by the line are joined nicely, whether they are just joined by the closest corners, or whether they are just left as rectangles - defaults to `true`
  ///  - [curveSmoothening] - controls the amount of curve segments per curve, if [prettyPaint] is enabled - defaults to 50
  ///  - [overlap] - usually controls the rendering if [prettyPaint] is disabled - defaults to 0
  ///
  /// Set [prettyPaint] to `false` and [overlap] to `-1` to get the 'reduced' appearance. Or, set to `0` to get the normal appearance, and `1` to get the rectangles that are actually downloaded.
  ///
  /// Set [prettyPaint] to `true` and [overlap] to `-1` to get the rectangles joined by their nearest corners. Setting to `0` will show the line with joining curves - the default. Setting to `1` will cause an error.
  ///
  /// Disabling [prettyPaint] will increase speed and is recommended on slower devices. Decreasing the [curveSmoothening] will also increase speed - set to a smaller value if corners are likely to be small (for example along a route).
  ///
  /// Returns a [PolygonLayerOptions] to be added to the `layer` property of a [FlutterMap].
  @override
  PolygonLayerOptions toDrawable(
    Color fillColor,
    Color borderColor, {
    double borderStrokeWidth = 3.0,
    bool isDotted = false,
    bool prettyPaint = true,
    int curveSmoothening = 50,
    int overlap = 0,
  }) {
    if (overlap >= -1 && overlap <= 1) {
      throw ArgumentError('`overlap` must be between -1 and 1 inclusive');
    }
    if (prettyPaint ? overlap == 0 || overlap == -1 : true) {
      throw ArgumentError(
          '`overlap` must be either -1 or 0 when `prettyPaint` is enabled');
    }

    final List<List<LatLng>> rects = toOutlines(prettyPaint ? -1 : overlap);

    final List<List<LatLng>> curves = [];

    if (prettyPaint) {
      final double diameter = (radius * math.pi / 4).round() * 2;

      List<double> intersectLine(LatLng p1, LatLng p2) {
        final double a = p1.latitude - p2.latitude;
        final double b = p2.longitude - p1.longitude;
        final double c =
            p1.longitude * p2.latitude - p2.longitude * p1.latitude;
        return [a, b, -c];
      }

      LatLng? intersectPoint(List<double> l1, List<double> l2) {
        final double d = l1[0] * l2[1] - l1[1] * l2[0];
        final double dx = l1[2] * l2[1] - l1[1] * l2[2];
        final double dy = l1[0] * l2[2] - l1[2] * l2[0];
        if (d != 0) {
          return LatLng(dy / d, dx / d);
        } else {
          return null;
        }
      }

      for (int i = 0; i <= rects.length - 2; i++) {
        final List<LatLng> topLineCurrent = [rects[i][3], rects[i][2]];
        final List<LatLng> bottomLineCurrent = [rects[i][0], rects[i][1]];

        final List<LatLng> topLineNext = [rects[i + 1][3], rects[i + 1][2]];
        final List<LatLng> bottomLineNext = [rects[i + 1][0], rects[i + 1][1]];

        final LatLng? intersectionA = intersectPoint(
          intersectLine(topLineCurrent[0], topLineCurrent[1]),
          intersectLine(topLineNext[0], topLineNext[1]),
        );
        final LatLng? intersectionB = intersectPoint(
          intersectLine(bottomLineCurrent[0], bottomLineCurrent[1]),
          intersectLine(bottomLineNext[0], bottomLineNext[1]),
        );

        if (intersectionA == null || intersectionB == null) {
          throw StateError(
              'Well done! You seemed to have create a rectangle exactly parallel to your previous one. Needless to say, this is extremely unlikely, and I haven\'t handled this. If this happened honestly, please report an error.');
        }

        const Distance distance = Distance();

        final bool aCurve = distance.distance(rects[i][2], intersectionA) >
            distance.distance(rects[i][1], intersectionB);

        final LatLng old1 = rects[i][aCurve ? 1 : 2];
        rects[i][aCurve ? 1 : 2] = aCurve ? intersectionB : intersectionA;
        rects[i][aCurve ? 2 : 1] = distance.offset(
          rects[i][aCurve ? 1 : 2],
          diameter,
          distance.bearing(old1, rects[i][aCurve ? 2 : 1]),
        );
        final LatLng old2 = rects[i + 1][aCurve ? 0 : 3];
        rects[i + 1][aCurve ? 0 : 3] = aCurve ? intersectionB : intersectionA;
        rects[i + 1][aCurve ? 3 : 0] = distance.offset(
          rects[i + 1][aCurve ? 0 : 3],
          diameter,
          distance.bearing(old2, rects[i + 1][aCurve ? 3 : 0]),
        );

        if (overlap != -1) {
          final QuadraticBezier curve = QuadraticBezier(
            [
              Vector2(
                rects[i][aCurve ? 2 : 1].longitude,
                rects[i][aCurve ? 2 : 1].latitude,
              ),
              aCurve
                  ? Vector2(intersectionA.longitude, intersectionA.latitude)
                  : Vector2(intersectionB.longitude, intersectionB.latitude),
              Vector2(
                rects[i + 1][aCurve ? 3 : 0].longitude,
                rects[i + 1][aCurve ? 3 : 0].latitude,
              ),
            ],
          );

          curves.add([]);

          for (var ii = 0; ii <= curveSmoothening; ii++) {
            curves[i].add(LatLng(curve.pointAt(ii / curveSmoothening).y,
                curve.pointAt(ii / curveSmoothening).x));
          }

          curves[i].add(aCurve ? intersectionB : intersectionA);
        }
      }
    }

    final List<Polygon> returnable = rects
        .map(
          (rect) => Polygon(
            color: fillColor,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
            isDotted: isDotted,
            points: rect,
          ),
        )
        .toList();

    if (prettyPaint && overlap != -1) {
      returnable.addAll(
        curves.map(
          (curve) => Polygon(
            color: fillColor,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
            isDotted: isDotted,
            points: curve,
          ),
        ),
      );
    }

    return PolygonLayerOptions(polygons: returnable);
  }

  /// This method is unavailable for this region type: use [toOutlines] instead
  @alwaysThrows
  @override
  List<LatLng> toList() {
    throw UnsupportedError(
        '`toList` is invalid for this region type: use `toOutlines()` instead');
  }
}
