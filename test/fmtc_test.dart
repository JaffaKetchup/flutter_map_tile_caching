// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: avoid_print

import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_tile_caching/src/bulk_download/tile_loops/shared.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

void main() {
  Future<int> countByGenerator(DownloadableRegion<BaseRegion> region) async {
    final tileRecievePort = ReceivePort();
    final tileIsolate = await Isolate.spawn(
      region.when(
        rectangle: (_) => TilesGenerator.rectangleTiles,
        circle: (_) => TilesGenerator.circleTiles,
        line: (_) => TilesGenerator.lineTiles,
        customPolygon: (_) => TilesGenerator.customPolygonTiles,
      ),
      (sendPort: tileRecievePort.sendPort, region: region),
      onExit: tileRecievePort.sendPort,
      debugName: '[FMTC] Tile Coords Generator Thread',
    );
    late final SendPort requestTilePort;

    int evts = -1;

    await for (final evt in tileRecievePort) {
      if (evt == null) break;
      if (evt is SendPort) requestTilePort = evt;
      requestTilePort.send(null);
      evts++;
    }

    tileIsolate.kill(priority: Isolate.immediate);
    tileRecievePort.close();

    return evts;
  }

  group(
    'Rectangle Region',
    () {
      final rectRegion = RectangleRegion(
        LatLngBounds(const LatLng(-1, -1), const LatLng(1, 1)),
      ).toDownloadable(minZoom: 1, maxZoom: 16, options: TileLayer());

      test(
        'Count By Counter',
        () => expect(TilesCounter.rectangleTiles(rectRegion), 179196),
      );

      test(
        'Count By Generator',
        () async => expect(await countByGenerator(rectRegion), 179196),
      );

      test(
        'Counter Duration',
        () => print(
          '${List.generate(
            2000,
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

      test(
        'Generator Duration',
        () async {
          final clock = Stopwatch()..start();
          await countByGenerator(rectRegion);
          clock.stop();
          print('${clock.elapsedMilliseconds / 1000} s');
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  group(
    'Circle Region',
    () {
      final circleRegion = CircleRegion(const LatLng(0, 0), 200)
          .toDownloadable(minZoom: 1, maxZoom: 15, options: TileLayer());

      test(
        'Count By Counter',
        () => expect(TilesCounter.circleTiles(circleRegion), 61564),
      );

      test(
        'Count By Generator',
        () async => expect(await countByGenerator(circleRegion), 61564),
      );

      test(
        'Counter Duration',
        () => print(
          '${List.generate(
            500,
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

      test(
        'Generator Duration',
        () async {
          final clock = Stopwatch()..start();
          await countByGenerator(circleRegion);
          clock.stop();
          print('${clock.elapsedMilliseconds / 1000} s');
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  group(
    'Line Region',
    () {
      final lineRegion = LineRegion(
        [const LatLng(-1, -1), const LatLng(1, 1), const LatLng(1, -1)],
        5000,
      ).toDownloadable(minZoom: 1, maxZoom: 15, options: TileLayer());

      test(
        'Count By Counter',
        () => expect(TilesCounter.lineTiles(lineRegion), 5040),
      );

      test(
        'Count By Generator',
        () async => expect(await countByGenerator(lineRegion), 5040),
      );

      test(
        'Counter Duration',
        () => print(
          '${List.generate(
            300,
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

      test(
        'Generator Duration',
        () async {
          final clock = Stopwatch()..start();
          await countByGenerator(lineRegion);
          clock.stop();
          print('${clock.elapsedMilliseconds / 1000} s');
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  group(
    'Custom Polygon Region',
    () {
      final customPolygonRegion1 = CustomPolygonRegion([
        const LatLng(51.45818683312154, -0.9674646220840917),
        const LatLng(51.55859639937614, -0.9185366064186982),
        const LatLng(51.476641197796724, -0.7494743298246318),
        const LatLng(51.56029831737391, -0.5322770067805148),
        const LatLng(51.235701626195365, -0.5746290119276093),
        const LatLng(51.38781341753136, -0.6779891095601829),
      ]).toDownloadable(minZoom: 1, maxZoom: 17, options: TileLayer());

      final customPolygonRegion2 = CustomPolygonRegion([
        const LatLng(-1, -1),
        const LatLng(1, -1),
        const LatLng(1, 1),
        const LatLng(-1, 1),
      ]).toDownloadable(minZoom: 1, maxZoom: 17, options: TileLayer());

      test(
        'Count By Counter',
        () => expect(
          TilesCounter.customPolygonTiles(customPolygonRegion1),
          15962,
        ),
      );

      test(
        'Count By Generator',
        () async => expect(await countByGenerator(customPolygonRegion1), 15962),
      );

      test(
        'Count By Counter (Compare to Rectangle Region)',
        () => expect(
          TilesCounter.customPolygonTiles(customPolygonRegion2),
          712096,
        ),
      );

      test(
        'Count By Generator (Compare to Rectangle Region)',
        () async =>
            expect(await countByGenerator(customPolygonRegion2), 712096),
      );

      test(
        'Counter Duration',
        () => print(
          '${List.generate(
            500,
            (index) {
              final clock = Stopwatch()..start();
              TilesCounter.customPolygonTiles(customPolygonRegion1);
              clock.stop();
              return clock.elapsedMilliseconds;
            },
            growable: false,
          ).average} ms',
        ),
      );

      test(
        'Generator Duration',
        () async {
          final clock = Stopwatch()..start();
          await countByGenerator(customPolygonRegion1);
          clock.stop();
          print('${clock.elapsedMilliseconds / 1000} s');
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

/*
 Future<Set<(int, int, int)>> listGenerator(
        DownloadableRegion<BaseRegion> region,
      ) async {
        final tileRecievePort = ReceivePort();
        final tileIsolate = await Isolate.spawn(
          region.when(
            rectangle: (_) => TilesGenerator.rectangleTiles,
            circle: (_) => TilesGenerator.circleTiles,
            line: (_) => TilesGenerator.lineTiles,
            customPolygon: (_) => TilesGenerator.customPolygonTiles,
          ),
          (sendPort: tileRecievePort.sendPort, region: region),
          onExit: tileRecievePort.sendPort,
          debugName: '[FMTC] Tile Coords Generator Thread',
        );
        late final SendPort requestTilePort;

        final Set<(int, int, int)> evts = {};

        await for (final evt in tileRecievePort) {
          if (evt == null) break;
          if (evt is SendPort) {
            requestTilePort = evt..send(null);
            continue;
          }
          requestTilePort.send(null);
          evts.add(evt);
        }

        tileIsolate.kill(priority: Isolate.immediate);
        tileRecievePort.close();

        return evts;
      }
*/
