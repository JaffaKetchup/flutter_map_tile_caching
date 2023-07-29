// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'shared.dart';

class TilesCounter {
  static int rectangleTiles(DownloadableRegion region) {
    final tileSize = _getTileSize(region);
    final bounds = (region.originalRegion as RectangleRegion).bounds;

    int numberOfTiles = 0;
    for (int zoomLvl = region.minZoom; zoomLvl <= region.maxZoom; zoomLvl++) {
      final CustomPoint<num> nwCustomPoint = region.crs
          .latLngToPoint(bounds.northWest, zoomLvl.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final CustomPoint<num> seCustomPoint = region.crs
              .latLngToPoint(bounds.southEast, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          const CustomPoint(1, 1);

      numberOfTiles += (seCustomPoint.x - nwCustomPoint.x + 1).toInt() *
          (seCustomPoint.y - nwCustomPoint.y + 1).toInt();
    }
    return numberOfTiles;
  }

  static int circleTiles(DownloadableRegion region) {
    // This took some time and is fairly complicated, so this is the overall explanation:
    // 1. Given a `LatLng` for every x degrees on a circle's circumference, convert it into a tile number
    // 2. Using a `Map` per zoom level, record all the X values in it without duplicates
    // 3. Under the previous record, add all the Y values within the circle (ie. to opposite the X value)
    // 4. Loop over these XY values and add them to the list
    // Theoretically, this could have been done using the same method as `lineTiles`, but `lineTiles` was built after this algorithm and this makes more sense for a circle

    final tileSize = _getTileSize(region);
    final circleOutline = region.originalRegion.toOutline();

    // Format: Map<z, Map<x, List<y>>>
    final Map<int, Map<int, List<int>>> outlineTileNums = {};

    int numberOfTiles = 0;

    for (int zoomLvl = region.minZoom; zoomLvl <= region.maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = <int, List<int>>{};

      for (final LatLng node in circleOutline) {
        final CustomPoint<num> tile = region.crs
            .latLngToPoint(node, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .floor();

        outlineTileNums[zoomLvl]![tile.x.toInt()] ??= [
          9223372036854775807,
          -9223372036854775808,
        ];

        outlineTileNums[zoomLvl]![tile.x.toInt()] = [
          tile.y < outlineTileNums[zoomLvl]![tile.x.toInt()]![0]
              ? tile.y.toInt()
              : outlineTileNums[zoomLvl]![tile.x.toInt()]![0],
          tile.y > outlineTileNums[zoomLvl]![tile.x.toInt()]![1]
              ? tile.y.toInt()
              : outlineTileNums[zoomLvl]![tile.x.toInt()]![1],
        ];
      }

      for (final int x in outlineTileNums[zoomLvl]!.keys) {
        numberOfTiles += outlineTileNums[zoomLvl]![x]![1] -
            outlineTileNums[zoomLvl]![x]![0] +
            1;
      }
    }

    return numberOfTiles;
  }

  static int lineTiles(DownloadableRegion region) {
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
          final int i2 = (i1 + 1) % polygon.points.length;
          final CustomPoint<num> p1 = polygon.points[i1];
          final CustomPoint<num> p2 = polygon.points[i2];

          final CustomPoint<num> normal =
              CustomPoint<num>(p2.y - p1.y, p1.x - p2.x);

          double minA = double.infinity;
          double maxA = double.negativeInfinity;

          for (final CustomPoint<num> p in a.points) {
            final num projected = normal.x * p.x + normal.y * p.y;

            if (projected < minA) minA = projected.toDouble();
            if (projected > maxA) maxA = projected.toDouble();
          }

          double minB = double.infinity;
          double maxB = double.negativeInfinity;

          for (final CustomPoint<num> p in b.points) {
            final num projected = normal.x * p.x + normal.y * p.y;

            if (projected < minB) minB = projected.toDouble();
            if (projected > maxB) maxB = projected.toDouble();
          }

          if (maxA < minB || maxB < minA) return false;
        }
      }

      return true;
    }

    final tileSize = _getTileSize(region);
    final lineOutline = (region.originalRegion as LineRegion).toOutlines(1);

    int numberOfTiles = 0;

    for (int zoomLvl = region.minZoom; zoomLvl <= region.maxZoom; zoomLvl++) {
      for (final rect in lineOutline) {
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

        final CustomPoint<num> rrNorthWest = region.crs
            .latLngToPoint(rrTopLeft, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .floor();
        final CustomPoint<num> rrNorthEast = region.crs
                .latLngToPoint(rrTopRight, zoomLvl.toDouble())
                .unscaleBy(tileSize)
                .ceil() -
            const CustomPoint(1, 0);
        final CustomPoint<num> rrSouthWest = region.crs
                .latLngToPoint(rrBottomLeft, zoomLvl.toDouble())
                .unscaleBy(tileSize)
                .ceil() -
            const CustomPoint(0, 1);
        final CustomPoint<num> rrSouthEast = region.crs
                .latLngToPoint(rrBottomRight, zoomLvl.toDouble())
                .unscaleBy(tileSize)
                .ceil() -
            const CustomPoint(1, 1);

        final CustomPoint<num> srNorthWest = region.crs
            .latLngToPoint(
              LatLng(rrAllLat.max, rrAllLon.min),
              zoomLvl.toDouble(),
            )
            .unscaleBy(tileSize)
            .floor();
        final CustomPoint<num> srSouthEast = region.crs
                .latLngToPoint(
                  LatLng(rrAllLat.min, rrAllLon.max),
                  zoomLvl.toDouble(),
                )
                .unscaleBy(tileSize)
                .ceil() -
            const CustomPoint(1, 1);

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
              numberOfTiles++;
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
}
