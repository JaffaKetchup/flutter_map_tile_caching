// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: avoid_print

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_tile_caching/src/bulk_download/tile_loops/custom_polygon_tools/earcut.dart';
import 'package:flutter_map_tile_caching/src/bulk_download/tile_loops/shared.dart';
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

    final customPolygonRegion = CustomPolygonRegion([
      const LatLng(51.45818683312154, -0.9674646220840917),
      const LatLng(51.55859639937614, -0.9185366064186982),
      const LatLng(51.476641197796724, -0.7494743298246318),
      const LatLng(51.56029831737391, -0.5322770067805148),
      const LatLng(51.235701626195365, -0.5746290119276093),
      const LatLng(51.38781341753136, -0.6779891095601829),
    ]).toDownloadable(minZoom: 1, maxZoom: 18, options: TileLayer());

    test(
      'Custom Polygon Region Count',
      () => expect(TilesCounter.customPolygonTiles(customPolygonRegion), 62234),
    );

    test(
      'Custom Polygon Region Duration',
      () => print(
        '${List.generate(
          100,
          (index) {
            final clock = Stopwatch()..start();
            TilesCounter.customPolygonTiles(customPolygonRegion);
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