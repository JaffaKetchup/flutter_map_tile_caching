// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'shared.dart';

/// A set of methods for each type of [BaseRegion] that generates the coordinates
/// of every tile within the specified [DownloadableRegion]
///
/// Each method should handle a [DownloadableRegion] with a specific generic type
/// [BaseRegion]. If a method is passed a non-compatible region, it is expected
/// to throw a `CastError`.
///
/// These methods must be run within seperate isolates, as they do heavy,
/// potentially lengthy computation. They do perform multiple-communication,
/// sending a new coordinate after they recieve a request message only. They will
/// kill themselves after there are no tiles left to generate.
///
/// See [TileCounters] for methods that do not generate each coordinate, but
/// just count the number of tiles with a more efficient method.
///
/// The number of tiles returned by each method must match the number of tiles
/// returned by the respective method in [TileCounters]. This is enforced by
/// automated tests.
@internal
class TileGenerators {
  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [RectangleRegion]
  @internal
  static Future<void> rectangleTiles(
    ({SendPort sendPort, DownloadableRegion region}) input,
  ) async {
    final region = input.region as DownloadableRegion<RectangleRegion>;
    final northWest = region.originalRegion.bounds.northWest;
    final southEast = region.originalRegion.bounds.southEast;

    final receivePort = ReceivePort();
    input.sendPort.send(receivePort.sendPort);
    final requestQueue = StreamQueue(receivePort);

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final nwPoint = (region.crs.latLngToPoint(northWest, zoomLvl) /
              region.options.tileSize)
          .floor();
      final sePoint = (region.crs.latLngToPoint(southEast, zoomLvl) /
                  region.options.tileSize)
              .ceil() -
          const Point(1, 1);

      for (int x = nwPoint.x; x <= sePoint.x; x++) {
        for (int y = nwPoint.y; y <= sePoint.y; y++) {
          tileCounter++;
          if (tileCounter < start || tileCounter > end) continue;
          await requestQueue.next;
          input.sendPort.send((x, y, zoomLvl.toInt()));
        }
      }
    }

    Isolate.exit();
  }

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [CircleRegion]
  @internal
  static Future<void> circleTiles(
    ({SendPort sendPort, DownloadableRegion region}) input,
  ) async {
    // This took some time and is fairly complicated, so this is the overall explanation:
    // 1. Given a `LatLng` for every x degrees on a circle's circumference, convert it into a tile number
    // 2. Using a `Map` per zoom level, record all the X values in it without duplicates
    // 3. Under the previous record, add all the Y values within the circle (ie. to opposite the X value)
    // 4. Loop over these XY values and add them to the list
    // Theoretically, this could have been done using the same method as `lineTiles`, but `lineTiles` was built after this algorithm and this makes more sense for a circle
    // Could also implement with the simpler method:
    // 1. Calculate the radius in tiles using `Distance`
    // 2. Iterate through y, then x
    // 3. Use the circle formula x^2 + y^2 = r^2 to determine all points within the radius
    // However, effectively scaling this proved to be difficult.

    final region = input.region as DownloadableRegion<CircleRegion>;
    final circleOutline = region.originalRegion.toOutline();

    final receivePort = ReceivePort();
    input.sendPort.send(receivePort.sendPort);
    final requestQueue = StreamQueue(receivePort);

    // Format: Map<z, Map<x, List<y>>>
    final Map<int, Map<int, List<int>>> outlineTileNums = {};

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    for (int zoomLvl = region.minZoom; zoomLvl <= region.maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};

      for (final node in circleOutline) {
        final tile = (region.crs.latLngToPoint(node, zoomLvl.toDouble()) /
                region.options.tileSize)
            .floor();

        outlineTileNums[zoomLvl]![tile.x] ??= [largestInt, smallestInt];
        outlineTileNums[zoomLvl]![tile.x] = [
          if (tile.y < outlineTileNums[zoomLvl]![tile.x]![0])
            tile.y
          else
            outlineTileNums[zoomLvl]![tile.x]![0],
          if (tile.y > outlineTileNums[zoomLvl]![tile.x]![1])
            tile.y
          else
            outlineTileNums[zoomLvl]![tile.x]![1],
        ];
      }

      for (final x in outlineTileNums[zoomLvl]!.keys) {
        for (int y = outlineTileNums[zoomLvl]![x]![0];
            y <= outlineTileNums[zoomLvl]![x]![1];
            y++) {
          tileCounter++;
          if (tileCounter < start || tileCounter > end) continue;
          await requestQueue.next;
          input.sendPort.send((x, y, zoomLvl));
        }
      }
    }

    Isolate.exit();
  }

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [LineRegion]
  @internal
  static Future<void> lineTiles(
    ({SendPort sendPort, DownloadableRegion region}) input,
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

    final region = input.region as DownloadableRegion<LineRegion>;
    final lineOutline = region.originalRegion.toOutlines(1);

    final receivePort = ReceivePort();
    input.sendPort.send(receivePort.sendPort);
    final requestQueue = StreamQueue(receivePort);

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

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

        final rotatedRectangleNW =
            (region.crs.latLngToPoint(rotatedRectangle.topLeft, zoomLvl) /
                    region.options.tileSize)
                .floor();
        final rotatedRectangleNE =
            (region.crs.latLngToPoint(rotatedRectangle.topRight, zoomLvl) /
                        region.options.tileSize)
                    .ceil() -
                const Point(1, 0);
        final rotatedRectangleSW =
            (region.crs.latLngToPoint(rotatedRectangle.bottomLeft, zoomLvl) /
                        region.options.tileSize)
                    .ceil() -
                const Point(0, 1);
        final rotatedRectangleSE =
            (region.crs.latLngToPoint(rotatedRectangle.bottomRight, zoomLvl) /
                        region.options.tileSize)
                    .ceil() -
                const Point(1, 1);

        final straightRectangleNW = (region.crs.latLngToPoint(
                  LatLng(rotatedRectangleLats.max, rotatedRectangleLngs.min),
                  zoomLvl,
                ) /
                region.options.tileSize)
            .floor();
        final straightRectangleSE = (region.crs.latLngToPoint(
                      LatLng(
                        rotatedRectangleLats.min,
                        rotatedRectangleLngs.max,
                      ),
                      zoomLvl,
                    ) /
                    region.options.tileSize)
                .ceil() -
            const Point(1, 1);

        for (int x = straightRectangleNW.x; x <= straightRectangleSE.x; x++) {
          bool foundOverlappingTile = false;
          for (int y = straightRectangleNW.y; y <= straightRectangleSE.y; y++) {
            tileCounter++;
            if (tileCounter < start || tileCounter > end) continue;
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

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [CustomPolygonRegion]
  @internal
  static Future<void> customPolygonTiles(
    ({SendPort sendPort, DownloadableRegion region}) input,
  ) async {
    final region = input.region as DownloadableRegion<CustomPolygonRegion>;
    final customPolygonOutline = region.originalRegion.outline;

    final receivePort = ReceivePort();
    input.sendPort.send(receivePort.sendPort);
    final requestQueue = StreamQueue(receivePort);

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final allOutlineTiles = <Point<int>>{};

      final pointsOutline = customPolygonOutline
          .map((e) => region.crs.latLngToPoint(e, zoomLvl).floor());

      for (final triangle in Earcut.triangulateFromPoints(
        pointsOutline.map((e) => e.toDoublePoint()),
      ).map(pointsOutline.elementAt).slices(3)) {
        final outlineTiles = {
          ..._bresenhamsLGA(
            Point(triangle[0].x, triangle[0].y),
            Point(triangle[1].x, triangle[1].y),
            unscaleBy: region.options.tileSize,
          ),
          ..._bresenhamsLGA(
            Point(triangle[1].x, triangle[1].y),
            Point(triangle[2].x, triangle[2].y),
            unscaleBy: region.options.tileSize,
          ),
          ..._bresenhamsLGA(
            Point(triangle[2].x, triangle[2].y),
            Point(triangle[0].x, triangle[0].y),
            unscaleBy: region.options.tileSize,
          ),
        };
        allOutlineTiles.addAll(outlineTiles);

        final byY = <int, Set<int>>{};
        for (final Point(:x, :y) in outlineTiles) {
          (byY[y] ??= {}).add(x);
        }

        for (final MapEntry(key: y, value: xs) in byY.entries) {
          final xsRawMin = xs.min;
          int i = 0;
          for (; xs.contains(xsRawMin + i); i++) {}
          final xsMin = xsRawMin + i;

          final xsRawMax = xs.max;
          i = 0;
          for (; xs.contains(xsRawMax - i); i++) {}
          final xsMax = xsRawMax - i;

          for (int x = xsMin; x <= xsMax; x++) {
            await requestQueue.next;
            input.sendPort.send((x, y, zoomLvl.toInt()));
          }
        }
      }

      for (final Point(:x, :y) in allOutlineTiles) {
        tileCounter++;
        if (tileCounter < start || tileCounter > end) continue;
        await requestQueue.next;
        input.sendPort.send((x, y, zoomLvl.toInt()));
      }
    }

    Isolate.exit();
  }
}
