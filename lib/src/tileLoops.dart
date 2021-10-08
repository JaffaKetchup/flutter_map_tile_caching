import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:latlong2/latlong.dart';

import 'misc.dart';

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
      final CustomPoint<num> tile = crs
          .latLngToPoint(node, zoomLvl.toDouble())
          .unscaleBy(tileSize)
          .floor();

      if (outlineTileNums[zoomLvl]![tile.x.toInt()] == null)
        outlineTileNums[zoomLvl]![tile.x.toInt()] = [
          999999999999999999,
          -999999999999999999
        ];

      outlineTileNums[zoomLvl]![tile.x.toInt()] = [
        tile.y.toInt() < (outlineTileNums[zoomLvl]![tile.x.toInt()]![0])
            ? tile.y.toInt()
            : (outlineTileNums[zoomLvl]![tile.x.toInt()]![0]),
        tile.y.toInt() > (outlineTileNums[zoomLvl]![tile.x.toInt()]![1])
            ? tile.y.toInt()
            : (outlineTileNums[zoomLvl]![tile.x.toInt()]![1]),
      ];
    }

    for (int x in outlineTileNums[zoomLvl]!.keys) {
      for (int y = outlineTileNums[zoomLvl]![x]![0];
          y <= outlineTileNums[zoomLvl]![x]![1];
          y++) {
        coords.add(
          Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble(),
        );
      }
    }
  }

  return coords;
}

List<Coords<num>> lineTiles(Map<String, dynamic> input) {
  bool overlap(Polygon a, Polygon b) {
    for (int x = 0; x < 2; x++) {
      final Polygon polygon = (x == 0) ? a : b;

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
      // Process inputs into readable variables
      final LatLng rrBottomLeft = rect[0];
      final LatLng rrBottomRight = rect[1];
      final LatLng rrTopRight = rect[2];
      final LatLng rrTopLeft = rect[3];

      // Construct lists with all points for each axis
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

      // Use constructed lists to get the straight rectangle corners
      final LatLng srTopLeft = LatLng(rrAllLat.maxNum, rrAllLon.minNum);
      //final LatLng srTopRight = LatLng(rrAllLat.maxNum, rrAllLon.maxNum);
      //final LatLng srBottomLeft = LatLng(rrAllLat.minNum, rrAllLon.minNum);
      final LatLng srBottomRight = LatLng(rrAllLat.minNum, rrAllLon.maxNum);

      // Get tile number for each rotated rectangle corner
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

      // Get tile number for each straight rectangle corner
      final srNorthWest = crs
          .latLngToPoint(srTopLeft, zoomLvl.toDouble())
          .unscaleBy(tileSize)
          .floor();
      /*final srNorthEast = crs
              .latLngToPoint(srTopRight, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 0);
      final srSouthWest = crs
              .latLngToPoint(srBottomLeft, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(0, 1);*/
      final srSouthEast = crs
              .latLngToPoint(srBottomRight, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);

      for (num x = srNorthWest.x; x <= srSouthEast.x; x++) {
        for (num y = srNorthWest.y; y <= srSouthEast.y; y++) {
          if (overlap(
            Polygon(
              rrNorthWest,
              rrNorthEast,
              rrSouthEast,
              rrSouthWest,
            ),
            Polygon(
              CustomPoint(x, y),
              CustomPoint(x + 1, y),
              CustomPoint(x + 1, y + 1),
              CustomPoint(x, y + 1),
            ),
          )) coords.add(Coords(x, y)..z = zoomLvl);
        }
      }
    }
  }

  return coords;
}

class Polygon {
  final CustomPoint<num> nw;
  final CustomPoint<num> ne;
  final CustomPoint<num> se;
  final CustomPoint<num> sw;

  Polygon(this.nw, this.ne, this.se, this.sw);

  List<CustomPoint<num>> get points => [nw, ne, se, sw];
}
