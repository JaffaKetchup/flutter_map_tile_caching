// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:isolate';
import 'dart:math';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dart_earcut/dart_earcut.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

import '../../../../flutter_map_tile_caching.dart';
import '../../../misc/int_extremes.dart';

part 'count.dart';
part 'generate.dart';

@immutable
class _Polygon {
  _Polygon((int, int) nw, (int, int) ne, (int, int) se, (int, int) sw)
      : points = [nw, ne, se, sw] {
    hashCode = Object.hashAll(points);
  }

  final List<(int, int)> points;

  @override
  late final int hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _Polygon && hashCode == other.hashCode);
}

/// Bresenham’s line generation algorithm, ported (with minor API differences)
/// from [anushaihalapathirana/Bresenham-line-drawing-algorithm](https://github.com/anushaihalapathirana/Bresenham-line-drawing-algorithm).
Iterable<(int, int)> _bresenhamsLGA(
  (double, double) start,
  (double, double) end, {
  int unscaleBy = 1,
}) sync* {
  final dx = end.$1 - start.$1;
  final dy = end.$2 - start.$2;
  final absdx = dx.abs();
  final absdy = dy.abs();

  var x = start.$1;
  var y = start.$2;
  yield ((x, y) / unscaleBy).floor();

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
      yield ((x, y) / unscaleBy).floor();
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
      yield ((x, y) / unscaleBy).floor();
    }
  }
}

extension on (double, double) {
  (double, double) operator /(num other) => ($1 / other, $2 / other);

  (int, int) floor() => ($1.floor(), $2.floor());
  (double, double) floorToDouble() => ($1.floorToDouble(), $2.floorToDouble());
  (int, int) ceil() => ($1.ceil(), $2.ceil());
}

extension on (int, int) {
  (int, int) operator -((int, int) other) => ($1 - other.$1, $2 - other.$2);
}
