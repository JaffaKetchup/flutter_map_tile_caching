import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/src/bulkDownload/downloadProgress.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() {
  Future<Directory> reset([bool dontReset = false]) async {
    final cacheDir = await MapCachingManager.normalCache;
    if (!dontReset && cacheDir.existsSync())
      try {
        cacheDir.deleteSync(recursive: true);
      } catch (e) {}
    return cacheDir;
  }

  test('preventRedownload', () async {
    final Directory parentDirectory = await reset();
    final MapCachingManager mainManager =
        MapCachingManager(parentDirectory, 'preventRedownload');
    final StorageCachingTileProvider provider = StorageCachingTileProvider(
      parentDirectory: parentDirectory,
      storeName: 'preventRedownload',
    );

    final Stream<DownloadProgress> downloadA = provider.downloadRegion(
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
        parallelThreads: 2,
      ),
      preDownloadChecksCallback: null,
    );

    DownloadProgress? progA;
    await for (DownloadProgress progress in downloadA) {
      progA = progress;
      print(
        ' > ' +
            progress.avgDurationTile.toString() +
            ' - ' +
            progress.duration.toString() +
            ' - ' +
            progress.estTotalDuration.toString() +
            ' - ' +
            progress.estRemainingDuration.toString(),
      );
    }

    expect(progA!.successfulTiles, 78);
    expect(progA.failedTiles, []);
    expect(progA.attemptedTiles, progA.successfulTiles);
    expect(progA.existingTiles, 0);
    expect(progA.existingTilesDiscount, 0);
    expect(progA.seaTiles, 0);
    expect(progA.seaTilesDiscount, 0);
    expect(mainManager.storeLength, progA.successfulTiles);

    final Stream<DownloadProgress> downloadB = provider.downloadRegion(
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
        parallelThreads: 2,
      ),
      preDownloadChecksCallback: null,
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

    final Stream<DownloadProgress> downloadC = provider.downloadRegion(
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
        parallelThreads: 2,
      ),
      preDownloadChecksCallback: null,
    );

    DownloadProgress? progC;
    await for (DownloadProgress progress in downloadC) {
      progC = progress;
      print(
        ' > ' +
            progress.avgDurationTile.toString() +
            ' - ' +
            progress.duration.toString() +
            ' - ' +
            progress.estTotalDuration.toString() +
            ' - ' +
            progress.estRemainingDuration.toString(),
      );
    }

    expect(progC!.successfulTiles, 78);
    expect(progC.failedTiles, []);
    expect(progC.attemptedTiles, progC.successfulTiles);
    expect(progC.existingTiles, 0);
    expect(progC.existingTilesDiscount, 0);
    expect(progC.seaTiles, 0);
    expect(progC.seaTilesDiscount, 0);
    expect(mainManager.storeLength, progC.successfulTiles);
  }, timeout: Timeout(Duration(minutes: 1)));

  test('seaTileRemoval', () async {
    final Directory parentDirectory = await reset(true);
    final MapCachingManager mainManager =
        MapCachingManager(parentDirectory, 'seaTileRemoval');
    final StorageCachingTileProvider provider = StorageCachingTileProvider(
      parentDirectory: parentDirectory,
      storeName: 'seaTileRemoval',
    );

    final Stream<DownloadProgress> download = provider.downloadRegion(
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
        parallelThreads: 2,
      ),
      preDownloadChecksCallback: null,
    );

    DownloadProgress? prog;
    await for (DownloadProgress progress in download) {
      print(
        ' > ' +
            progress.avgDurationTile.toString() +
            ' - ' +
            progress.duration.toString() +
            ' - ' +
            progress.estTotalDuration.toString() +
            ' - ' +
            progress.estRemainingDuration.toString() +
            ' | ' +
            progress.seaTilesDiscount.toStringAsFixed(2) +
            '%',
      );
      prog = progress;
    }

    expect(prog!.successfulTiles, 552);
    expect(prog.failedTiles, []);
    expect(prog.attemptedTiles, prog.successfulTiles);
    expect(prog.existingTiles, 0);
    expect(prog.existingTilesDiscount, 0);
    expect(prog.seaTiles, 291);
    expect(prog.seaTilesDiscount.toStringAsFixed(2), '52.72');
    expect(mainManager.storeLength, 261);
    expect(prog.successfulTiles - prog.seaTiles, mainManager.storeLength);
  }, timeout: Timeout(Duration(minutes: 1)));
}
