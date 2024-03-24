// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:isolate';
import 'dart:math';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dart_earcut/dart_earcut.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import '../../../flutter_map_tile_caching.dart';
import '../../misc/int_extremes.dart';

part 'count.dart';
part 'generate.dart';

class _Polygon {
  _Polygon(Point<int> nw, Point<int> ne, Point<int> se, Point<int> sw)
      : points = [nw, ne, se, sw] {
    hashCode = Object.hashAll(points);
  }

  final List<Point<int>> points;

  @override
  late final int hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _Polygon && hashCode == other.hashCode);
}

/// Bresenham’s line generation algorithm, ported (with minor API differences)
/// from [anushaihalapathirana/Bresenham-line-drawing-algorithm](https://github.com/anushaihalapathirana/Bresenham-line-drawing-algorithm).
Iterable<Point<int>> _bresenhamsLGA(
  Point<int> start,
  Point<int> end, {
  double unscaleBy = 1,
}) sync* {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final absdx = dx.abs();
  final absdy = dy.abs();

  var x = start.x;
  var y = start.y;
  yield Point((x / unscaleBy).floor(), (y / unscaleBy).floor());

  if (absdx > absdy) {
    var d = 2 * absdy - absdx;

    for (var i = 0; i < absdx; i++) {
      x = dx < 0 ? x - 1 : x + 1;
      if (d < 0) {
        d = d + 2 * absdy;
      } else {
        y = dy < 0 ? y - 1 : y + 1;
        d = d + (2 * absdy - 2 * absdx);
      }
      yield Point((x / unscaleBy).floor(), (y / unscaleBy).floor());
    }
  } else {
    // case when slope is greater than or equals to 1
    var d = 2 * absdx - absdy;

    for (var i = 0; i < absdy; i++) {
      y = dy < 0 ? y - 1 : y + 1;
      if (d < 0) {
        d = d + 2 * absdx;
      } else {
        x = dx < 0 ? x - 1 : x + 1;
        d = d + (2 * absdx) - (2 * absdy);
      }
      yield Point((x / unscaleBy).floor(), (y / unscaleBy).floor());
    }
  }
}
