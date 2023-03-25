// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:isolate';
import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:latlong2/latlong.dart';

import '../../../flutter_map_tile_caching.dart';

part 'count.dart';
part 'generate.dart';

class _Polygon {
  final CustomPoint<num> nw;
  final CustomPoint<num> ne;
  final CustomPoint<num> se;
  final CustomPoint<num> sw;

  _Polygon(this.nw, this.ne, this.se, this.sw);

  List<CustomPoint<num>> get points => [nw, ne, se, sw];
}

extension on List<double> {
  double get minNum => reduce(min);
  double get maxNum => reduce(max);
}

Map<String, dynamic> generateTileLoopsInput(DownloadableRegion region) {
  Iterable<List<E>> chunked<E>(List<E> list, int size) sync* {
    final length = list.length;
    for (var i = 0; i < length; i += size) {
      yield list.sublist(i, (i + size < length) ? i + size : length);
    }
  }

  return {
    'rectOutline': LatLngBounds.fromPoints(region.points.cast()),
    'circleOutline': region.points,
    'lineOutline': chunked(region.points, 4).toList(),
    'minZoom': region.minZoom,
    'maxZoom': region.maxZoom,
    'crs': region.crs,
    'tileSize': CustomPoint(region.options.tileSize, region.options.tileSize),
  };
}
