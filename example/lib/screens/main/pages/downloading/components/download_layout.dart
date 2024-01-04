import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/exts/size_formatter.dart';
import '../state/downloading_provider.dart';
import 'main_statistics.dart';
import 'multi_linear_progress_indicator.dart';
import 'stat_display.dart';

class DownloadLayout extends StatelessWidget {
  const DownloadLayout({
    super.key,
    required this.storeDirectory,
    required this.download,
    required this.moveToMapPage,
  });

  final FMTCStore storeDirectory;
  final DownloadProgress download;
  final void Function() moveToMapPage;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox.square(
                      dimension: 216,
                      child: download.latestTileEvent.tileImage != null
                          ? Image.memory(
                              download.latestTileEvent.tileImage!,
                              gaplessPlayback: true,
                            )
                          : const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                MainStatistics(
                  download: download,
                  storeDirectory: storeDirectory,
                  moveToMapPage: moveToMapPage,
                ),
                const SizedBox(width: 32),
                const VerticalDivider(),
                const SizedBox(width: 16),
                Expanded(
                  child: Table(
                    children: [
                      TableRow(
                        children: [
                          StatDisplay(
                            statistic:
                                '${download.cachedTiles - download.bufferedTiles} + ${download.bufferedTiles}',
                            description: 'cached + buffered tiles',
                          ),
                          StatDisplay(
                            statistic:
                                '${((download.cachedSize - download.bufferedSize) * 1024).asReadableSize} + ${(download.bufferedSize * 1024).asReadableSize}',
                            description: 'cached + buffered size',
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          StatDisplay(
                            statistic:
                                '${download.skippedTiles} (${download.skippedTiles == 0 ? 0 : (100 - ((download.cachedTiles - download.skippedTiles) / download.cachedTiles) * 100).toStringAsFixed(1)}%)',
                            description: 'skipped tiles (% saving)',
                          ),
                          StatDisplay(
                            statistic:
                                '${(download.skippedSize * 1024).asReadableSize} (${download.skippedTiles == 0 ? 0 : (100 - ((download.cachedSize - download.skippedSize) / download.cachedSize) * 100).toStringAsFixed(1)}%)',
                            description: 'skipped size (% saving)',
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          RepaintBoundary(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      download.failedTiles.toString(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: download.failedTiles == 0
                                            ? null
                                            : Colors.red,
                                      ),
                                    ),
                                    if (download.failedTiles != 0) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.warning_amber,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'failed tiles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: download.failedTiles == 0
                                        ? null
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          MulitLinearProgressIndicator(
            maxValue: download.maxTiles,
            backgroundChild: Text(
              '${download.remainingTiles}',
              style: const TextStyle(color: Colors.white),
            ),
            progresses: [
              (
                value: download.cachedTiles +
                    download.skippedTiles +
                    download.failedTiles,
                color: Colors.red,
                child: Text(
                  '${download.failedTiles}',
                  style: const TextStyle(color: Colors.black),
                )
              ),
              (
                value: download.cachedTiles + download.skippedTiles,
                color: Colors.yellow,
                child: Text(
                  '${download.skippedTiles}',
                  style: const TextStyle(color: Colors.black),
                )
              ),
              (
                value: download.cachedTiles,
                color: Colors.green[300]!,
                child: Text(
                  '${download.bufferedTiles}',
                  style: const TextStyle(color: Colors.black),
                )
              ),
              (
                value: download.cachedTiles - download.bufferedTiles,
                color: Colors.green,
                child: Text(
                  '${download.cachedTiles - download.bufferedTiles}',
                  style: const TextStyle(color: Colors.white),
                )
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'FAILED TILES',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: Selector<DownloadingProvider, List<TileEvent>>(
                      selector: (context, provider) => provider.failedTiles,
                      builder: (context, failedTiles, _) => failedTiles.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task_alt, size: 48),
                                SizedBox(height: 10),
                                Text('Any failed tiles will appear here'),
                              ],
                            )
                          : ListView.builder(
                              reverse: true,
                              addRepaintBoundaries: false,
                              itemCount: failedTiles.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: Icon(
                                  switch (failedTiles[index].result) {
                                    TileEventResult.noConnectionDuringFetch =>
                                      Icons.wifi_off,
                                    TileEventResult.unknownFetchException =>
                                      Icons.error,
                                    TileEventResult.negativeFetchResponse =>
                                      Icons.reply,
                                    _ => Icons.abc,
                                  },
                                ),
                                title: Text(failedTiles[index].url),
                                subtitle: Text(
                                  switch (failedTiles[index].result) {
                                    TileEventResult.noConnectionDuringFetch =>
                                      'Failed to establish a connection to the network',
                                    TileEventResult.unknownFetchException =>
                                      'There was an unknown error when trying to download this tile, of type ${failedTiles[index].fetchError.runtimeType}',
                                    TileEventResult.negativeFetchResponse =>
                                      'The tile server responded with an HTTP status code of ${failedTiles[index].fetchResponse!.statusCode} (${failedTiles[index].fetchResponse!.reasonPhrase})',
                                    _ => throw Error(),
                                  },
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'SKIPPED TILES',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: Selector<DownloadingProvider, List<TileEvent>>(
                      selector: (context, provider) => provider.skippedTiles,
                      builder: (context, skippedTiles, _) =>
                          skippedTiles.isEmpty
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.task_alt, size: 48),
                                    SizedBox(height: 10),
                                    Text('Any skipped tiles will appear here'),
                                  ],
                                )
                              : ListView.builder(
                                  reverse: true,
                                  addRepaintBoundaries: false,
                                  itemCount: skippedTiles.length,
                                  itemBuilder: (context, index) => ListTile(
                                    leading: Icon(
                                      switch (skippedTiles[index].result) {
                                        TileEventResult.alreadyExisting =>
                                          Icons.disabled_visible,
                                        TileEventResult.isSeaTile =>
                                          Icons.water_drop,
                                        _ => Icons.abc,
                                      },
                                    ),
                                    title: Text(skippedTiles[index].url),
                                    subtitle: Text(
                                      switch (skippedTiles[index].result) {
                                        TileEventResult.alreadyExisting =>
                                          'Tile already exists',
                                        TileEventResult.isSeaTile =>
                                          'Tile is a sea tile',
                                        _ => throw Error(),
                                      },
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
