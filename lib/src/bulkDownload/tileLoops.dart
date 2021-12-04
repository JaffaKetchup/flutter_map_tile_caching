import 'dart:math';

import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:latlong2/latlong.dart';

List<Coords<num>> rectangleTiles(Map<String, dynamic> input) {
  final LatLngBounds bounds = input['bounds'];
  final int minZoom = input['minZoom'];
  final int maxZoom = input['maxZoom'];
  final Crs crs = input['crs'];
  final CustomPoint<num> tileSize = input['tileSize'];

  final coords = <Coords<num>>[];
  for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
    final nwCustomPoint = crs
        .latLngToPoint(bounds.northWest, zoomLvl.toDouble())
        .unscaleBy(tileSize)
        .floor();
    final seCustomPoint = crs
            .latLngToPoint(bounds.southEast, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .ceil() -
        CustomPoint(1, 1);
    for (num x = nwCustomPoint.x; x <= seCustomPoint.x; x++) {
      for (num y = nwCustomPoint.y; y <= seCustomPoint.y; y++) {
        coords.add(Coords(x, y)..z = zoomLvl);
      }
    }
  }
  return coords;
}

List<Coords<num>> circleTiles(Map<String, dynamic> input) {
  // This took some time and is fairly complicated, so this is the overall explanation:
  // 1. Given a `LatLng` for every x degrees on a circle's circumference, convert it into a tile number
  // 2. Using a `Map` per zoom level, record all the X values in it without duplicates
  // 3. Under the previous record, add all the Y values within the circle (ie. to opposite the X value)
  // 4. Loop over these XY values and add them to the list
  // Theoretically, this could have been done using the same method as `lineTiles`, but `lineTiles` was built after this algorithm and this makes more sense for a circle

  final List<LatLng> circleOutline = input['circleOutline'];
  final int minZoom = input['minZoom'];
  final int maxZoom = input['maxZoom'];
  final Crs crs = input['crs'];
  final CustomPoint<num> tileSize = input['tileSize'];

  final Map<int, Map<int, List<int>>> outlineTileNums = {};

  final List<Coords<num>> coords = [];

  for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
    outlineTileNums[zoomLvl] = {};

    for (LatLng node in circleOutline) {
      final tile = crs
          .latLngToPoint(node, zoomLvl.toDouble())
          .unscaleBy(tileSize)
          .floor() as CustomPoint<int>;

      outlineTileNums[zoomLvl]![tile.x] ??= [1000000000000, -1000000000000];

      outlineTileNums[zoomLvl]![tile.x] = [
        tile.y < outlineTileNums[zoomLvl]![tile.x]![0]
            ? tile.y
            : outlineTileNums[zoomLvl]![tile.x]![0],
        tile.y > outlineTileNums[zoomLvl]![tile.x]![1]
            ? tile.y
            : outlineTileNums[zoomLvl]![tile.x]![1],
      ];
    }

    for (int x in outlineTileNums[zoomLvl]!.keys)
      for (int y = outlineTileNums[zoomLvl]![x]![0];
          y <= outlineTileNums[zoomLvl]![x]![1];
          y++)
        coords.add(Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble());
  }

  return coords;
}

List<Coords<num>> lineTiles(Map<String, dynamic> input) {
  // This took some time and is fairly complicated, so this is the overall explanation:
  // 1. Given 4 `LatLng` points, create a 'straight' rectangle around the 'rotated' rectangle, that can be defined with just 2 `LatLng` points
  // 2. Convert the straight rectangle into tile numbers, and loop through the same as `rectangleTiles`
  // 3. For every generated tile number (which represents top-left of the tile), generate the rest of the tile corners
  // 4. Check whether the square tile overlaps the rotated rectangle from the start, add it to the list if it does
  // 5. Keep track of the number of overlaps per row: if there was one overlap and now there isn't, skip the rest of the row because we can be sure there are no more tiles

  // Overlap algorithm originally in Python, available at https://stackoverflow.com/a/56962827/11846040
  bool overlap(_Polygon a, _Polygon b) {
    for (int x = 0; x < 2; x++) {
      final _Polygon polygon = (x == 0) ? a : b;

      for (int i1 = 0; i1 < polygon.points.length; i1++) {
        final int i2 = (i1 + 1) % polygon.points.length;
        final CustomPoint<num> p1 = polygon.points[i1];
        final CustomPoint<num> p2 = polygon.points[i2];

        final CustomPoint<num> normal =
            CustomPoint<num>(p2.y - p1.y, p1.x - p2.x);

        double minA = double.infinity;
        double maxA = double.negativeInfinity;

        for (CustomPoint<num> p in a.points) {
          final num projected = normal.x * p.x + normal.y * p.y;

          if (projected < minA) minA = projected.toDouble();
          if (projected > maxA) maxA = projected.toDouble();
        }

        double minB = double.infinity;
        double maxB = double.negativeInfinity;

        for (CustomPoint<num> p in b.points) {
          final num projected = normal.x * p.x + normal.y * p.y;

          if (projected < minB) minB = projected.toDouble();
          if (projected > maxB) maxB = projected.toDouble();
        }

        if (maxA < minB || maxB < minA) return false;
      }
    }

    return true;
  }

  final List<List<LatLng>> rects = input['lineOutline'];
  final int minZoom = input['minZoom'];
  final int maxZoom = input['maxZoom'];
  final Crs crs = input['crs'];
  final CustomPoint<num> tileSize = input['tileSize'];

  final coords = <Coords<num>>[];

  for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
    for (List<LatLng> rect in rects) {
      final LatLng rrBottomLeft = rect[0];
      final LatLng rrBottomRight = rect[1];
      final LatLng rrTopRight = rect[2];
      final LatLng rrTopLeft = rect[3];

      final List<double> rrAllLat = [
        rrTopLeft.latitude,
        rrTopRight.latitude,
        rrBottomLeft.latitude,
        rrBottomRight.latitude,
      ];
      final List<double> rrAllLon = [
        rrTopLeft.longitude,
        rrTopRight.longitude,
        rrBottomLeft.longitude,
        rrBottomRight.longitude,
      ];

      final rrNorthWest = crs
          .latLngToPoint(rrTopLeft, zoomLvl.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final rrNorthEast = crs
              .latLngToPoint(rrTopRight, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 0);
      final rrSouthWest = crs
              .latLngToPoint(rrBottomLeft, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(0, 1);
      final rrSouthEast = crs
              .latLngToPoint(rrBottomRight, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);

      final srNorthWest = crs
          .latLngToPoint(
            LatLng(rrAllLat.maxNum, rrAllLon.minNum),
            zoomLvl.toDouble(),
          )
          .unscaleBy(tileSize)
          .floor();
      final srSouthEast = crs
              .latLngToPoint(
                LatLng(rrAllLat.minNum, rrAllLon.maxNum),
                zoomLvl.toDouble(),
              )
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);

      for (num x = srNorthWest.x; x <= srSouthEast.x; x++) {
        bool foundOverlappingTile = false;
        for (num y = srNorthWest.y; y <= srSouthEast.y; y++) {
          if (overlap(
            _Polygon(
              rrNorthWest,
              rrNorthEast,
              rrSouthEast,
              rrSouthWest,
            ),
            _Polygon(
              CustomPoint(x, y),
              CustomPoint(x + 1, y),
              CustomPoint(x + 1, y + 1),
              CustomPoint(x, y + 1),
            ),
          )) {
            coords.add(Coords(x, y)..z = zoomLvl);
            foundOverlappingTile = true;
          } else if (foundOverlappingTile) break;
        }
      }
    }
  }

  return coords;
}

class _Polygon {
  final CustomPoint<num> nw;
  final CustomPoint<num> ne;
  final CustomPoint<num> se;
  final CustomPoint<num> sw;

  _Polygon(this.nw, this.ne, this.se, this.sw);

  List<CustomPoint<num>> get points => [nw, ne, se, sw];
}

extension on List<double> {
  double get minNum => this.reduce(min);
  double get maxNum => this.reduce(max);
}
