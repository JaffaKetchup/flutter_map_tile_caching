import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() {
  Future<Directory> reset([bool dontReset = false]) async {
    final cacheDir = await MapCachingManager.normalDirectory;
    if (!dontReset && cacheDir.existsSync())
      cacheDir.deleteSync(recursive: true);
    return cacheDir;
  }

  test('preventRedownload', () async {
    final Directory parentDirectory = await reset();
    final MapCachingManager mainManager =
        MapCachingManager(parentDirectory, 'preventRedownload');

    final Stream<DownloadProgress> downloadA = StorageCachingTileProvider(
      parentDirectory: parentDirectory,
      storeName: 'preventRedownload',
    ).downloadRegion(
      RectangleRegion(
        LatLngBounds(
          LatLng(51.50263458922777, -0.6815800359919895),
          LatLng(51.48672619988095, -0.6508706762001888),
        ),
      ).toDownloadable(
        1,
        16,
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
      ),
    );

    DownloadProgress? progA;
    await for (DownloadProgress progress in downloadA) {
      progA = progress;
      print(
          ' A > ' + progress.approxPercentageComplete.toStringAsFixed(2) + '%');
    }

    expect(progA!.successfulTiles, 78);
    expect(progA.failedTiles, []);
    expect(progA.attemptedTiles, progA.successfulTiles);
    expect(progA.existingTiles, 0);
    expect(progA.existingTilesDiscount, 0);
    expect(progA.seaTiles, 0);
    expect(progA.seaTilesDiscount, 0);
    expect(mainManager.storeLength, progA.successfulTiles);

    final Stream<DownloadProgress> downloadB = StorageCachingTileProvider(
      parentDirectory: parentDirectory,
      storeName: 'preventRedownload',
    ).downloadRegion(
      RectangleRegion(
        LatLngBounds(
          LatLng(51.50263458922777, -0.6815800359919895),
          LatLng(51.48672619988095, -0.6508706762001888),
        ),
      ).toDownloadable(
        1,
        16,
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        preventRedownload: true,
      ),
    );

    DownloadProgress? progB;
    await for (DownloadProgress progress in downloadB) progB = progress;

    expect(progB!.successfulTiles, 78);
    expect(progB.failedTiles, []);
    expect(progB.attemptedTiles, progB.successfulTiles);
    expect(progB.existingTiles, progB.successfulTiles);
    expect(progB.existingTilesDiscount, 100);
    expect(progB.seaTiles, 0);
    expect(progB.seaTilesDiscount, 0);
    expect(mainManager.storeLength, progB.successfulTiles);

    final Stream<DownloadProgress> downloadC = StorageCachingTileProvider(
      parentDirectory: parentDirectory,
      storeName: 'preventRedownload',
    ).downloadRegion(
      RectangleRegion(
        LatLngBounds(
          LatLng(51.50263458922777, -0.6815800359919895),
          LatLng(51.48672619988095, -0.6508706762001888),
        ),
      ).toDownloadable(
        1,
        16,
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
      ),
    );

    DownloadProgress? progC;
    await for (DownloadProgress progress in downloadC) {
      progC = progress;
      print(
          ' C > ' + progress.approxPercentageComplete.toStringAsFixed(2) + '%');
    }

    expect(progC!.successfulTiles, 78);
    expect(progC.failedTiles, []);
    expect(progC.attemptedTiles, progC.successfulTiles);
    expect(progC.existingTiles, progC.successfulTiles);
    expect(progC.existingTilesDiscount, 100);
    expect(progC.seaTiles, 0);
    expect(progC.seaTilesDiscount, 0);
    expect(mainManager.storeLength, progC.successfulTiles);
  }, timeout: Timeout(Duration(minutes: 1)));
  test(
    'compressionQuality',
    () async {
      final Directory parentDirectory = await reset(true);
      final MapCachingManager mainManager =
          MapCachingManager(parentDirectory, 'compressionQuality');

      final Stream<DownloadProgress> download = StorageCachingTileProvider(
        parentDirectory: parentDirectory,
        storeName: 'compressionQuality',
      ).downloadRegion(
        RectangleRegion(
          LatLngBounds(
            LatLng(51.50263458922777, -0.6815800359919895),
            LatLng(51.48672619988095, -0.6508706762001888),
          ),
        ).toDownloadable(
          1,
          16,
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          compressionQuality: 50,
        ),
      );

      await for (DownloadProgress progress in download) {
        print(
            ' > ' + progress.approxPercentageComplete.toStringAsFixed(2) + '%');
        expect(progress.failedTiles.length, 0);
      }

      expect(mainManager.storeLength, 78);
    },
    timeout: Timeout(Duration(minutes: 1)),
    onPlatform: {'windows': Skip('Does not work on Windows')},
  );

  test('seaColor', () async {
    final Directory parentDirectory = await reset(true);
    final MapCachingManager mainManager =
        MapCachingManager(parentDirectory, 'seaTileRemoval');

    final Stream<DownloadProgress> download = StorageCachingTileProvider(
      parentDirectory: parentDirectory,
      storeName: 'seaTileRemoval',
    ).downloadRegion(
      RectangleRegion(
        LatLngBounds(
          LatLng(52.734269449384044, 1.6816567389157684),
          LatLng(52.720316794641235, 1.7098770389649511),
        ),
      ).toDownloadable(
        1,
        18,
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        seaTileRemoval: true,
      ),
    );

    DownloadProgress? prog;
    await for (DownloadProgress progress in download) {
      print(
        ' O > ' +
            progress.attemptedTiles.toString() +
            ' - ' +
            progress.approxPercentageComplete.toStringAsFixed(2) +
            '%',
      );
      print(
        ' S > ' +
            progress.seaTiles.toString() +
            ' - ' +
            progress.seaTilesDiscount.toStringAsFixed(2) +
            '%',
      );
      prog = progress;
    }

    //expect(prog!.completedTiles - prog.erroredTiles.length, 0);
    //expect(mainManager.storeLength, 78);
  }, timeout: Timeout(Duration(minutes: 2)));
}
