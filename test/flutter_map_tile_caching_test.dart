// ignore_for_file: avoid_print

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
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
  });
}
