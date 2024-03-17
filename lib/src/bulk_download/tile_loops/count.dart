// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'shared.dart';

/// A set of methods for each type of [BaseRegion] that counts the number of
/// tiles within the specified [DownloadableRegion]
///
/// Each method should handle a [DownloadableRegion] with a specific generic type
/// [BaseRegion]. If a method is passed a non-compatible region, it is expected
/// to throw a `CastError`.
///
/// These methods should be run within seperate isolates, as they do heavy,
/// potentially lengthy computation. They do not perform multiple-communication,
/// and so only require simple Isolate protocols such as [Isolate.run].
///
/// Where possible, these methods do not generate every coordinate for improved
/// efficiency, as the number of tiles can be counted without looping through
/// them all (in most cases). See [TileGenerators] for methods that actually
/// generate the coordinates of each tile, but with added complexity.
///
/// The number of tiles returned by each method must match the number of tiles
/// returned by the respective method in [TileGenerators]. This is enforced by
/// automated tests.
@internal
class TileCounters {
  /// Returns the number of tiles within a [DownloadableRegion] with generic type
  /// [RectangleRegion]
  @internal
  static int rectangleTiles(DownloadableRegion region) {
    region as DownloadableRegion<RectangleRegion>;

    final northWest = region.originalRegion.bounds.northWest;
    final southEast = region.originalRegion.bounds.southEast;

    var numberOfTiles = 0;

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

      numberOfTiles +=
          (sePoint.x - nwPoint.x + 1) * (sePoint.y - nwPoint.y + 1);
    }

    return numberOfTiles;
  }

  /// Returns the number of tiles within a [DownloadableRegion] with generic type
  /// [CircleRegion]
  @internal
  static int circleTiles(DownloadableRegion region) {
    region as DownloadableRegion<CircleRegion>;

    final circleOutline = region.originalRegion.toOutline();

    // Format: Map<z, Map<x, List<y>>>
    final outlineTileNums = <int, Map<int, List<int>>>{};

    int numberOfTiles = 0;

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
        numberOfTiles += outlineTileNums[zoomLvl]![x]![1] -
            outlineTileNums[zoomLvl]![x]![0] +
            1;
      }
    }

    return numberOfTiles;
  }

  /// Returns the number of tiles within a [DownloadableRegion] with generic type
  /// [LineRegion]
  @internal
  static int lineTiles(DownloadableRegion region) {
    region as DownloadableRegion<LineRegion>;

    // Overlap algorithm originally in Python, available at
    // https://stackoverflow.com/a/56962827/11846040
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

  /// Returns the number of tiles within a [DownloadableRegion] with generic type
  /// [CustomPolygonRegion]
  @internal
  static int customPolygonTiles(DownloadableRegion region) {
    region as DownloadableRegion<CustomPolygonRegion>;

    final customPolygonOutline = region.originalRegion.outline;

    int numberOfTiles = 0;

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

        for (final xs in byY.values) {
          final xsRawMin = xs.min;
          int i = 0;
          for (; xs.contains(xsRawMin + i); i++) {}
          final xsMin = xsRawMin + i;

          final xsRawMax = xs.max;
          i = 0;
          for (; xs.contains(xsRawMax - i); i++) {}
          final xsMax = xsRawMax - i;

          if (xsMin <= xsMax) numberOfTiles += (xsMax - xsMin) + 1;
        }
      }

      numberOfTiles += allOutlineTiles.length;
    }

    return numberOfTiles;
  }
}
