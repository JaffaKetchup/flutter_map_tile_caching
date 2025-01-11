// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'shared.dart';

/// A set of methods for each type of [BaseRegion] that generates the
/// coordinates of every tile within the specified [DownloadableRegion]
///
/// These methods must be run within seperate isolates, as they do heavy,
/// potentially lengthy computation. They do perform multiple-communication,
/// sending a new coordinate after they recieve a request message only. They
/// will kill themselves after there are no tiles left to generate.
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
    ({SendPort sendPort, DownloadableRegion<RectangleRegion> region}) input, {
    StreamQueue? multiRequestQueue,
  }) async {
    final region = input.region;
    final sendPort = input.sendPort;
    final inMulti = multiRequestQueue != null;

    final StreamQueue requestQueue;
    if (inMulti) {
      requestQueue = multiRequestQueue;
    } else {
      final receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);
      requestQueue = StreamQueue(receivePort);
    }

    final northWest = region.originalRegion.bounds.northWest;
    final southEast = region.originalRegion.bounds.southEast;

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final intZoomLvl = zoomLvl.toInt();
      final scaleLvl = region.crs.scale(zoomLvl);

      final nw = region.crs.latLngToXY(northWest, scaleLvl);
      final nwX = (nw.$1 / region.options.tileDimension).floor();
      final nwY = (nw.$2 / region.options.tileDimension).floor();

      final se = region.crs.latLngToXY(southEast, scaleLvl);
      final seX = (se.$1 / region.options.tileDimension).ceil() - 1;
      final seY = (se.$2 / region.options.tileDimension).ceil() - 1;

      for (int x = nwX; x <= seX; x++) {
        for (int y = nwY; y <= seY; y++) {
          tileCounter++;
          if (tileCounter < start) continue;
          if (tileCounter > end) {
            if (!inMulti) Isolate.exit();
            return;
          }

          await requestQueue.next;
          sendPort.send((x, y, intZoomLvl));
        }
      }
    }

    if (!inMulti) Isolate.exit();
  }

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [CircleRegion]
  @internal
  static Future<void> circleTiles(
    ({SendPort sendPort, DownloadableRegion<CircleRegion> region}) input, {
    StreamQueue? multiRequestQueue,
  }) async {
    final region = input.region;
    final sendPort = input.sendPort;
    final inMulti = multiRequestQueue != null;

    final StreamQueue requestQueue;
    if (inMulti) {
      requestQueue = multiRequestQueue;
    } else {
      final receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);
      requestQueue = StreamQueue(receivePort);
    }

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    final edgeTile = const Distance(roundResult: false).offset(
      region.originalRegion.center,
      region.originalRegion.radius * 1000,
      0,
    );

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final intZoomLvl = zoomLvl.toInt();
      final scaleLvl = region.crs.scale(zoomLvl);

      final centerTile =
          (region.crs.latLngToXY(region.originalRegion.center, scaleLvl) /
                  region.options.tileDimension)
              .floor();

      final radius = centerTile.$2 -
          (region.crs.latLngToXY(edgeTile, scaleLvl).$2 /
                  region.options.tileDimension)
              .floor();

      final radiusSquared = radius * radius;

      if (radius == 0) {
        tileCounter++;
        if (tileCounter < start) continue;
        if (tileCounter > end) {
          if (!inMulti) Isolate.exit();
          return;
        }

        await requestQueue.next;
        sendPort.send((centerTile.$1, centerTile.$2, intZoomLvl));

        continue;
      }

      if (radius == 1) {
        tileCounter++;
        if (tileCounter >= start) {
          if (tileCounter > end) {
            if (!inMulti) Isolate.exit();
            return;
          }

          await requestQueue.next;
          sendPort.send((centerTile.$1, centerTile.$2, intZoomLvl));
        }

        tileCounter++;
        if (tileCounter >= start) {
          if (tileCounter > end) {
            if (!inMulti) Isolate.exit();
            return;
          }

          await requestQueue.next;
          sendPort.send((centerTile.$1, centerTile.$2 - 1, intZoomLvl));
        }

        tileCounter++;
        if (tileCounter >= start) {
          if (tileCounter > end) {
            if (!inMulti) Isolate.exit();
            return;
          }

          await requestQueue.next;
          sendPort.send((centerTile.$1 - 1, centerTile.$2, intZoomLvl));
        }

        tileCounter++;
        if (tileCounter >= start) {
          if (tileCounter > end) {
            if (!inMulti) Isolate.exit();
            return;
          }

          await requestQueue.next;
          sendPort.send((centerTile.$1 - 1, centerTile.$2 - 1, intZoomLvl));
        }

        continue;
      }

      for (int dy = 0; dy < radius; dy++) {
        final mdx = sqrt(radiusSquared - dy * dy).floor();
        for (int dx = -mdx - 1; dx <= mdx; dx++) {
          tileCounter++;
          if (tileCounter >= start) {
            if (tileCounter > end) {
              if (!inMulti) Isolate.exit();
              return;
            }

            await requestQueue.next;
            sendPort.send((dx + centerTile.$1, dy + centerTile.$2, intZoomLvl));
          }

          tileCounter++;
          if (tileCounter >= start) {
            if (tileCounter > end) {
              if (!inMulti) Isolate.exit();
              return;
            }

            await requestQueue.next;
            sendPort.send(
              (dx + centerTile.$1, -dy - 1 + centerTile.$2, intZoomLvl),
            );
          }
        }
      }
    }

    if (!inMulti) Isolate.exit();
  }

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [LineRegion]
  @internal
  static Future<void> lineTiles(
    ({SendPort sendPort, DownloadableRegion<LineRegion> region}) input, {
    StreamQueue? multiRequestQueue,
  }) async {
    // This took some time and is fairly complicated, so this is the overall
    // explanation:
    // 1. Given 4 `LatLng` points, create a 'straight' rectangle around the
    //    'rotated' rectangle, that can be defined with just 2 `LatLng` points
    // 2. Convert the straight rectangle into tile numbers, and loop through the
    //    same as `rectangleTiles`
    // 3. For every generated tile number (which represents top-left of the
    //    tile), generate the rest of the tile corners
    // 4. Check whether the square tile overlaps the rotated rectangle from the
    //    start, add it to the list if it does
    // 5. Keep track of the number of overlaps per row: if there was one overlap
    //    and now there isn't, skip the rest of the row because we can be sure
    //    there are no more tiles

    // Overlap algorithm originally in Python, available at https://stackoverflow.com/a/56962827/11846040
    bool overlap(_Polygon a, _Polygon b) {
      for (int x = 0; x < 2; x++) {
        final _Polygon polygon = x == 0 ? a : b;

        for (int i1 = 0; i1 < polygon.points.length; i1++) {
          final i2 = (i1 + 1) % polygon.points.length;
          final p1 = polygon.points[i1];
          final p2 = polygon.points[i2];

          final normal = Point(p2.$2 - p1.$2, p1.$1 - p2.$1);

          var minA = largestInt;
          var maxA = smallestInt;
          for (final p in a.points) {
            final projected = normal.x * p.$1 + normal.y * p.$2;
            if (projected < minA) minA = projected;
            if (projected > maxA) maxA = projected;
          }

          var minB = largestInt;
          var maxB = smallestInt;
          for (final p in b.points) {
            final projected = normal.x * p.$1 + normal.y * p.$2;
            if (projected < minB) minB = projected;
            if (projected > maxB) maxB = projected;
          }

          if (maxA < minB || maxB < minA) return false;
        }
      }

      return true;
    }

    final region = input.region;
    final sendPort = input.sendPort;
    final inMulti = multiRequestQueue != null;

    final StreamQueue requestQueue;
    if (inMulti) {
      requestQueue = multiRequestQueue;
    } else {
      final receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);
      requestQueue = StreamQueue(receivePort);
    }

    final lineOutline = region.originalRegion.toOutlines(1);

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final intZoomLvl = zoomLvl.toInt();
      final scaleLvl = region.crs.scale(zoomLvl);

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
            (region.crs.latLngToXY(rotatedRectangle.topLeft, scaleLvl) /
                    region.options.tileDimension)
                .floor();
        final rotatedRectangleNE =
            (region.crs.latLngToXY(rotatedRectangle.topRight, scaleLvl) /
                        region.options.tileDimension)
                    .ceil() -
                (1, 0);
        final rotatedRectangleSW =
            (region.crs.latLngToXY(rotatedRectangle.bottomLeft, scaleLvl) /
                        region.options.tileDimension)
                    .ceil() -
                (0, 1);
        final rotatedRectangleSE =
            (region.crs.latLngToXY(rotatedRectangle.bottomRight, scaleLvl) /
                        region.options.tileDimension)
                    .ceil() -
                (1, 1);

        final straightRectangleNW = (region.crs.latLngToXY(
                  LatLng(rotatedRectangleLats.max, rotatedRectangleLngs.min),
                  scaleLvl,
                ) /
                region.options.tileDimension)
            .floor();
        final straightRectangleSE = (region.crs.latLngToXY(
                      LatLng(
                        rotatedRectangleLats.min,
                        rotatedRectangleLngs.max,
                      ),
                      scaleLvl,
                    ) /
                    region.options.tileDimension)
                .ceil() -
            (1, 1);

        for (int x = straightRectangleNW.$1; x <= straightRectangleSE.$1; x++) {
          bool foundOverlappingTile = false;
          for (int y = straightRectangleNW.$2;
              y <= straightRectangleSE.$2;
              y++) {
            final tile =
                _Polygon((x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1));
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

              tileCounter++;
              if (tileCounter < start) continue;
              if (tileCounter > end) {
                if (!inMulti) Isolate.exit();
                return;
              }

              await requestQueue.next;
              sendPort.send((x, y, intZoomLvl));
            } else if (foundOverlappingTile) {
              break;
            }
          }
        }
      }
    }

    if (!inMulti) Isolate.exit();
  }

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [CustomPolygonRegion]
  @internal
  static Future<void> customPolygonTiles(
    ({
      SendPort sendPort,
      DownloadableRegion<CustomPolygonRegion> region
    }) input, {
    StreamQueue? multiRequestQueue,
  }) async {
    final region = input.region;
    final sendPort = input.sendPort;
    final inMulti = multiRequestQueue != null;

    final StreamQueue requestQueue;
    if (inMulti) {
      requestQueue = multiRequestQueue;
    } else {
      final receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);
      requestQueue = StreamQueue(receivePort);
    }

    int tileCounter = -1;
    final start = region.start - 1;
    final end = (region.end ?? double.infinity) - 1;

    for (double zoomLvl = region.minZoom.toDouble();
        zoomLvl <= region.maxZoom;
        zoomLvl++) {
      final intZoomLvl = zoomLvl.toInt();
      final scaleLvl = region.crs.scale(zoomLvl);

      final allOutlineTiles = <(int, int)>{};

      final pointsOutline = region.originalRegion.outline
          .map((e) => region.crs.latLngToXY(e, scaleLvl).floorToDouble());

      for (final triangle in Earcut.triangulateRaw(
        List.generate(
          pointsOutline.length * 2,
          (i) => i.isEven
              ? pointsOutline.elementAt(i ~/ 2).$1
              : pointsOutline.elementAt(i ~/ 2).$2,
          growable: false,
        ),
      ).map(pointsOutline.elementAt).slices(3)) {
        final outlineTiles = {
          ..._bresenhamsLGA(
            triangle[0],
            triangle[1],
            unscaleBy: region.options.tileDimension,
          ),
          ..._bresenhamsLGA(
            triangle[1],
            triangle[2],
            unscaleBy: region.options.tileDimension,
          ),
          ..._bresenhamsLGA(
            triangle[2],
            triangle[0],
            unscaleBy: region.options.tileDimension,
          ),
        };
        allOutlineTiles.addAll(outlineTiles);

        final byY = <int, Set<int>>{};
        for (final (x, y) in outlineTiles) {
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
            tileCounter++;
            if (tileCounter < start) continue;
            if (tileCounter > end) {
              if (!inMulti) Isolate.exit();
              return;
            }

            await requestQueue.next;
            sendPort.send((x, y, intZoomLvl));
          }
        }
      }

      for (final (x, y) in allOutlineTiles) {
        tileCounter++;
        if (tileCounter < start) continue;
        if (tileCounter > end) {
          if (!inMulti) Isolate.exit();
          return;
        }

        await requestQueue.next;
        sendPort.send((x, y, intZoomLvl));
      }
    }

    if (!inMulti) Isolate.exit();
  }

  /// Generate the coordinates of each tile within a [DownloadableRegion] with
  /// generic type [MultiRegion]
  @internal
  static Future<void> multiTiles(
    ({SendPort sendPort, DownloadableRegion<MultiRegion> region}) input, {
    StreamQueue? multiRequestQueue,
  }) async {
    final region = input.region;
    final inMulti = multiRequestQueue != null;

    final StreamQueue requestQueue;
    if (inMulti) {
      requestQueue = multiRequestQueue;
    } else {
      final receivePort = ReceivePort();
      input.sendPort.send(receivePort.sendPort);
      requestQueue = StreamQueue(receivePort);
    }

    for (final subRegion in region.originalRegion.regions) {
      await subRegion
          .toDownloadable(
            minZoom: region.minZoom,
            maxZoom: region.maxZoom,
            options: region.options,
            start: region.start,
            end: region.end,
            crs: region.crs,
          )
          .when(
            rectangle: (region) => rectangleTiles(
              (sendPort: input.sendPort, region: region),
              multiRequestQueue: requestQueue,
            ),
            circle: (region) => circleTiles(
              (sendPort: input.sendPort, region: region),
              multiRequestQueue: requestQueue,
            ),
            line: (region) => lineTiles(
              (sendPort: input.sendPort, region: region),
              multiRequestQueue: requestQueue,
            ),
            customPolygon: (region) => customPolygonTiles(
              (sendPort: input.sendPort, region: region),
              multiRequestQueue: requestQueue,
            ),
            multi: (region) => multiTiles(
              (sendPort: input.sendPort, region: region),
              multiRequestQueue: requestQueue,
            ),
          );
    }

    if (!inMulti) Isolate.exit();
  }
}
