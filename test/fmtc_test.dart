// ignore_for_file: avoid_print

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_tile_caching/src/bulk_download/tile_loops/shared.dart';
import 'package:flutter_map_tile_caching/src/misc/earcut.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

void main() {
  group('Test Region Tile Generation', () {
    final rectRegion =
        RectangleRegion(LatLngBounds(const LatLng(-2, -2), const LatLng(2, 2)))
            .toDownloadable(minZoom: 1, maxZoom: 18, options: TileLayer());

    test(
      'Rectangle Region Count',
      () => expect(TilesCounter.rectangleTiles(rectRegion), 11329252),
    );

    test(
      'Rectangle Region Duration',
      () => print(
        '${List.generate(
          1000,
          (index) {
            final clock = Stopwatch()..start();
            TilesCounter.rectangleTiles(rectRegion);
            clock.stop();
            return clock.elapsedMilliseconds;
          },
          growable: false,
        ).average} ms',
      ),
    );

    final circleRegion = CircleRegion(const LatLng(0, 0), 1000)
        .toDownloadable(minZoom: 1, maxZoom: 18, options: TileLayer());

    test(
      'Circle Region Count',
      () => expect(TilesCounter.circleTiles(circleRegion), 2989468),
    );

    test(
      'Circle Region Duration',
      () => print(
        '${List.generate(
          1000,
          (index) {
            final clock = Stopwatch()..start();
            TilesCounter.circleTiles(circleRegion);
            clock.stop();
            return clock.elapsedMilliseconds;
          },
          growable: false,
        ).average} ms',
      ),
    );

    final lineRegion =
        LineRegion([const LatLng(-1, -1), const LatLng(1, 1)], 100)
            .toDownloadable(minZoom: 1, maxZoom: 16, options: TileLayer());

    test(
      'Line Region Count',
      () => expect(TilesCounter.lineTiles(lineRegion), 2936),
    );

    test(
      'Line Region Duration',
      () => print(
        '${List.generate(
          100,
          (index) {
            final clock = Stopwatch()..start();
            TilesCounter.lineTiles(lineRegion);
            clock.stop();
            return clock.elapsedMilliseconds;
          },
          growable: false,
        ).average} ms',
      ),
    );
  });

  group('Test Earcutting Triangulation', () {
    test(
      'Simple Triangle',
      () => expect(Earcut.triangulateRaw([0, 0, 0, 50, 50, 00]), [1, 0, 2]),
    );

    test(
      'Complex Triangle',
      () => expect(
        Earcut.triangulateRaw([0, 0, 0, 25, 0, 50, 25, 25, 50, 0, 25, 0]),
        [1, 0, 5, 5, 4, 3, 3, 2, 1, 1, 5, 3],
      ),
    );

    test(
      'L Shape',
      () => expect(
        Earcut.triangulateRaw([0, 0, 10, 0, 10, 5, 5, 5, 5, 15, 0, 15]),
        [4, 5, 0, 0, 1, 2, 3, 4, 0, 0, 2, 3],
      ),
    );

    test(
      'Simple Polygon',
      () => expect(
        Earcut.triangulateRaw([10, 0, 0, 50, 60, 60, 70, 10]),
        [1, 0, 3, 3, 2, 1],
      ),
    );

    test(
      'Polygon With Hole',
      () => expect(
        Earcut.triangulateRaw(
          [0, 0, 100, 0, 100, 100, 0, 100, 20, 20, 80, 20, 80, 80, 20, 80],
          holeIndices: [4],
        ),
        [
          3,
          0,
          4,
          5,
          4,
          0,
          3,
          4,
          7,
          5,
          0,
          1,
          2,
          3,
          7,
          6,
          5,
          1,
          2,
          7,
          6,
          6,
          1,
          2
        ],
      ),
    );

    test(
      'Polygon With 3D Coords',
      () => expect(
        Earcut.triangulateRaw(
          [10, 0, 1, 0, 50, 2, 60, 60, 3, 70, 10, 4],
          dimensions: 3,
        ),
        [1, 0, 3, 3, 2, 1],
      ),
    );
  });
}
