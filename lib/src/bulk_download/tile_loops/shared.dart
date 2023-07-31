// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:isolate';
import 'dart:math';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:latlong2/latlong.dart';

import '../../../flutter_map_tile_caching.dart';
import '../../misc/int_extremes.dart';
import 'custom_polygon_tools/bres.dart';
import 'custom_polygon_tools/earcut.dart';

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

Point<double> _getTileSize(DownloadableRegion region) =>
    Point(region.options.tileSize, region.options.tileSize);
