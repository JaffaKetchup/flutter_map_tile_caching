// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'shared.dart';

class TilesGenerator {
  static Future<void> rectangleTiles(
    ({SendPort sendPort, DownloadableRegion<RectangleRegion> region}) input,
  ) async {
    final region = input.region;
    final tileSize = _getTileSize(region);
    final northWest = region.originalRegion.bounds.northWest;
    final southEast = region.originalRegion.bounds.southEast;

    final recievePort = ReceivePort();
    input.sendPort.send(recievePort.sendPort);
    final requestQueue = StreamQueue(recievePort);

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final nwPoint = region.crs
          .latLngToPoint(northWest, zoomLvl)
          .unscaleBy(tileSize)
          .floor();
      final sePoint = region.crs
              .latLngToPoint(southEast, zoomLvl)
              .unscaleBy(tileSize)
              .ceil() -
          const Point(1, 1);

      for (int x = nwPoint.x; x <= sePoint.x; x++) {
        for (int y = nwPoint.y; y <= sePoint.y; y++) {
          await requestQueue.next;
          input.sendPort.send((x, y, zoomLvl.toInt()));
        }
      }
    }

    Isolate.exit();
  }

  static Future<void> circleTiles(
    ({SendPort sendPort, DownloadableRegion<CircleRegion> region}) input,
  ) async {
    // This took some time and is fairly complicated, so this is the overall explanation:
    // 1. Given a `LatLng` for every x degrees on a circle's circumference, convert it into a tile number
    // 2. Using a `Map` per zoom level, record all the X values in it without duplicates
    // 3. Under the previous record, add all the Y values within the circle (ie. to opposite the X value)
    // 4. Loop over these XY values and add them to the list
    // Theoretically, this could have been done using the same method as `lineTiles`, but `lineTiles` was built after this algorithm and this makes more sense for a circle

    final region = input.region;
    final tileSize = _getTileSize(region);
    final circleOutline = region.originalRegion.toOutline();

    final recievePort = ReceivePort();
    input.sendPort.send(recievePort.sendPort);
    final requestQueue = StreamQueue(recievePort);

    // Format: Map<z, Map<x, List<y>>>
    final Map<int, Map<int, List<int>>> outlineTileNums = {};

    for (int zoomLvl = region.minZoom; zoomLvl <= region.maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};

      for (final node in circleOutline) {
        final tile = region.crs
            .latLngToPoint(node, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .floor();

        outlineTileNums[zoomLvl]![tile.x] ??= [largestInt, smallestInt];
        outlineTileNums[zoomLvl]![tile.x] = [
          tile.y < outlineTileNums[zoomLvl]![tile.x]![0]
              ? tile.y
              : outlineTileNums[zoomLvl]![tile.x]![0],
          tile.y > outlineTileNums[zoomLvl]![tile.x]![1]
              ? tile.y
              : outlineTileNums[zoomLvl]![tile.x]![1],
        ];
      }

      for (final x in outlineTileNums[zoomLvl]!.keys) {
        for (int y = outlineTileNums[zoomLvl]![x]![0];
            y <= outlineTileNums[zoomLvl]![x]![1];
            y++) {
          await requestQueue.next;
          input.sendPort.send((x, y, zoomLvl));
        }
      }
    }

    Isolate.exit();
  }

  static Future<void> lineTiles(
    ({SendPort sendPort, DownloadableRegion<LineRegion> region}) input,
  ) async {
    // This took some time and is fairly complicated, so this is the overall explanation:
    // 1. Given 4 `LatLng` points, create a 'straight' rectangle around the 'rotated' rectangle, that can be defined with just 2 `LatLng` points
    // 2. Convert the straight rectangle into tile numbers, and loop through the same as `rectangleTiles`
    // 3. For every generated tile number (which represents top-left of the tile), generate the rest of the tile corners
    // 4. Check whether the square tile overlaps the rotated rectangle from the start, add it to the list if it does
    // 5. Keep track of the number of overlaps per row: if there was one overlap and now there isn't, skip the rest of the row because we can be sure there are no more tiles

    // Overlap algorithm originally in Python, available at https://stackoverflow.com/a/56962827/11846040
    bool overlap(_Polygon a, _Polygon b) {
      for (int x = 0; x < 2; x++) {
        final _Polygon polygon = x == 0 ? a : b;

        for (int i1 = 0; i1 < polygon.points.length; i1++) {
          final i2 = (i1 + 1) % polygon.points.length;
          final p1 = polygon.points[i1];
          final p2 = polygon.points[i2];

          final normal = Point(p2.y - p1.y, p1.x - p2.x);

          var minA = largestInt;
          var maxA = smallestInt;
          for (final p in a.points) {
            final projected = normal.x * p.x + normal.y * p.y;
            if (projected < minA) minA = projected;
            if (projected > maxA) maxA = projected;
          }

          var minB = largestInt;
          var maxB = smallestInt;
          for (final p in b.points) {
            final projected = normal.x * p.x + normal.y * p.y;
            if (projected < minB) minB = projected;
            if (projected > maxB) maxB = projected;
          }

          if (maxA < minB || maxB < minA) return false;
        }
      }

      return true;
    }

    final region = input.region;
    final tileSize = _getTileSize(region);
    final lineOutline = region.originalRegion.toOutlines(1);

    final recievePort = ReceivePort();
    input.sendPort.send(recievePort.sendPort);
    final requestQueue = StreamQueue(recievePort);

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final generatedTiles = <int>[];

      for (final rect in lineOutline) {
        final rotatedRectangle = (
          bottomLeft: rect[0],
          bottomRight: rect[1],
          topRight: rect[2],
          topLeft: rect[3],
        );

        final rotatedRectangleLats = [
          rotatedRectangle.topLeft.latitude,
          rotatedRectangle.topRight.latitude,
          rotatedRectangle.bottomLeft.latitude,
          rotatedRectangle.bottomRight.latitude,
        ];
        final rotatedRectangleLngs = [
          rotatedRectangle.topLeft.longitude,
          rotatedRectangle.topRight.longitude,
          rotatedRectangle.bottomLeft.longitude,
          rotatedRectangle.bottomRight.longitude,
        ];

        final rotatedRectangleNW = region.crs
            .latLngToPoint(rotatedRectangle.topLeft, zoomLvl)
            .unscaleBy(tileSize)
            .floor();
        final rotatedRectangleNE = region.crs
                .latLngToPoint(rotatedRectangle.topRight, zoomLvl)
                .unscaleBy(tileSize)
                .ceil() -
            const Point(1, 0);
        final rotatedRectangleSW = region.crs
                .latLngToPoint(rotatedRectangle.bottomLeft, zoomLvl)
                .unscaleBy(tileSize)
                .ceil() -
            const Point(0, 1);
        final rotatedRectangleSE = region.crs
                .latLngToPoint(rotatedRectangle.bottomRight, zoomLvl)
                .unscaleBy(tileSize)
                .ceil() -
            const Point(1, 1);

        final straightRectangleNW = region.crs
            .latLngToPoint(
              LatLng(rotatedRectangleLats.max, rotatedRectangleLngs.min),
              zoomLvl,
            )
            .unscaleBy(tileSize)
            .floor();
        final straightRectangleSE = region.crs
                .latLngToPoint(
                  LatLng(rotatedRectangleLats.min, rotatedRectangleLngs.max),
                  zoomLvl,
                )
                .unscaleBy(tileSize)
                .ceil() -
            const Point(1, 1);

        for (int x = straightRectangleNW.x; x <= straightRectangleSE.x; x++) {
          bool foundOverlappingTile = false;
          for (int y = straightRectangleNW.y; y <= straightRectangleSE.y; y++) {
            final tile = _Polygon(
              Point(x, y),
              Point(x + 1, y),
              Point(x + 1, y + 1),
              Point(x, y + 1),
            );
            if (generatedTiles.contains(tile.hashCode)) continue;
            if (overlap(
              _Polygon(
                rotatedRectangleNW,
                rotatedRectangleNE,
                rotatedRectangleSE,
                rotatedRectangleSW,
              ),
              tile,
            )) {
              generatedTiles.add(tile.hashCode);
              foundOverlappingTile = true;
              await requestQueue.next;
              input.sendPort.send((x, y, zoomLvl.toInt()));
            } else if (foundOverlappingTile) {
              break;
            }
          }
        }
      }
    }

    Isolate.exit();
  }
}
