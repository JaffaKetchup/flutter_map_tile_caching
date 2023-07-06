// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:isolate';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:latlong2/latlong.dart';

import '../../../flutter_map_tile_caching.dart';
import '../../misc/int_extremes.dart';

part 'count.dart';
part 'generate.dart';

class _Polygon {
  _Polygon(this.nw, this.ne, this.se, this.sw) : points = [nw, ne, se, sw] {
    hashCode = Object.hashAllUnordered(points);
  }

  final CustomPoint<int> nw;
  final CustomPoint<int> ne;
  final CustomPoint<int> se;
  final CustomPoint<int> sw;
  final List<CustomPoint<int>> points;

  @override
  late final int hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _Polygon && hashCode == other.hashCode);
}

CustomPoint<double> _getTileSize(DownloadableRegion region) =>
    CustomPoint(region.options.tileSize, region.options.tileSize);
