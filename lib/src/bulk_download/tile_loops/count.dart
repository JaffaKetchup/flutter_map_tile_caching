// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'shared.dart';

class TilesCounter {
  static int rectangleTiles(DownloadableRegion region) {
    region as DownloadableRegion<RectangleRegion>;

    final tileSize = _getTileSize(region);
    final northWest = region.originalRegion.bounds.northWest;
    final southEast = region.originalRegion.bounds.southEast;

    var numberOfTiles = 0;

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

      numberOfTiles +=
          (sePoint.x - nwPoint.x + 1) * (sePoint.y - nwPoint.y + 1);
    }

    return numberOfTiles;
  }

  static int circleTiles(DownloadableRegion region) {
    region as DownloadableRegion<CircleRegion>;

    // This took some time and is fairly complicated, so this is the overall explanation:
    // 1. Given a `LatLng` for every x degrees on a circle's circumference, convert it into a tile number
    // 2. Using a `Map` per zoom level, record all the X values in it without duplicates
    // 3. Under the previous record, add all the Y values within the circle (ie. to opposite the X value)
    // 4. Loop over these XY values and add them to the list
    // Theoretically, this could have been done using the same method as `lineTiles`, but `lineTiles` was built after this algorithm and this makes more sense for a circle

    final tileSize = _getTileSize(region);
    final circleOutline = region.originalRegion.toOutline();

    // Format: Map<z, Map<x, List<y>>>
    final outlineTileNums = <int, Map<int, List<int>>>{};

    int numberOfTiles = 0;

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
        numberOfTiles += outlineTileNums[zoomLvl]![x]![1] -
            outlineTileNums[zoomLvl]![x]![0] +
            1;
      }
    }

    return numberOfTiles;
  }

  static int lineTiles(DownloadableRegion region) {
    region as DownloadableRegion<LineRegion>;

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

    final tileSize = _getTileSize(region);
    final lineOutline = region.originalRegion.toOutlines(1);

    int numberOfTiles = 0;

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
              numberOfTiles++;
              generatedTiles.add(tile.hashCode);
              foundOverlappingTile = true;
            } else if (foundOverlappingTile) {
              break;
            }
          }
        }
      }
    }

    return numberOfTiles;
  }

  static int customPolygonTiles(DownloadableRegion region) {
    region as DownloadableRegion<CustomPolygonRegion>;

    final customPolygonOutline = region.originalRegion.toOutline();

    int numberOfTiles = 0;

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final tiles = <Point<int>>{};
      final outlineTiles = <Point<int>>{};

      for (final triangle in Earcut.triangulateFromPoints(
        customPolygonOutline.map(region.crs.projection.project),
      ).map(customPolygonOutline.elementAt).slices(3)) {
        final vertex1 = region.crs.latLngToPoint(triangle[0], zoomLvl).round();
        final vertex2 = region.crs.latLngToPoint(triangle[1], zoomLvl).round();
        final vertex3 = region.crs.latLngToPoint(triangle[2], zoomLvl).round();

        outlineTiles.addAll([
          ...bresenhamsLGA(
            Point(vertex1.x, vertex1.y),
            Point(vertex2.x, vertex2.y),
          ).map((e) => (e / region.options.tileSize).floor()),
          ...bresenhamsLGA(
            Point(vertex2.x, vertex2.y),
            Point(vertex3.x, vertex3.y),
          ).map((e) => (e / region.options.tileSize).floor()),
          ...bresenhamsLGA(
            Point(vertex3.x, vertex3.y),
            Point(vertex1.x, vertex1.y),
          ).map((e) => (e / region.options.tileSize).floor()),
        ]);
      }

      tiles.addAll(outlineTiles);

      final byY = <int, List<int>>{};
      for (final tile in outlineTiles) {
        (byY[tile.y] ?? (byY[tile.y] = [])).add(tile.x);
      }

      for (int y = byY.keys.min; y <= byY.keys.max; y++) {
        byY[y]!.sort();
        for (int x = byY[y]!.first + 1; x < byY[y]!.last; x++) {
          tiles.add(Point(x, y));
        }
      }

      numberOfTiles += tiles.length;
    }

    return numberOfTiles;
  }
}
