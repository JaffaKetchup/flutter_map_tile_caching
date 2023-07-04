import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/vars/size_formatter.dart';
import 'multi_linear_progress_indicator.dart';
import 'stat_display.dart';

class DownloadLayout extends StatelessWidget {
  const DownloadLayout({
    super.key,
    required this.storeDirectory,
    required this.download,
  });

  final StoreDirectory storeDirectory;
  final DownloadProgress download;

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
                      dimension: 256 / 1.25,
                      child: download.lastTileEvent.tileImage != null
                          ? Image.memory(
                              download.lastTileEvent.tileImage!,
                              gaplessPlayback: true,
                            )
                          : const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatDisplay(
                      statistic:
                          '${download.percentageProgress.toStringAsFixed(2)}%',
                      description: 'percentage attempted',
                    ),
                    StatDisplay(
                      statistic: download.duration.toString().split('.')[0],
                      description: 'elapsed duration',
                    ),
                    const SizedBox(height: 16),
                    if (!download.hasFinished)
                      RepaintBoundary(
                        child: Row(
                          children: [
                            IconButton.outlined(
                              onPressed: storeDirectory.download.isPaused()
                                  ? () => storeDirectory.download.resume()
                                  : () => storeDirectory.download.pause(),
                              icon: Icon(
                                storeDirectory.download.isPaused()
                                    ? Icons.play_arrow
                                    : Icons.pause,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              onPressed: () => storeDirectory.download.cancel(),
                              icon: const Icon(Icons.cancel),
                            )
                          ],
                        ),
                      ),
                    if (download.hasFinished)
                      OutlinedButton(
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => Provider.of<DownloadProvider>(
                              context,
                              listen: false,
                            ).setDownloadProgress(null),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text('Exit'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 48),
                const VerticalDivider(),
                const SizedBox(width: 16),
                Expanded(
                  child: Table(
                    children: [
                      TableRow(
                        children: [
                          StatDisplay(
                            statistic: '${download.attemptedTiles}',
                            description: 'attempted tiles',
                          ),
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
                            statistic: '${download.remainingTiles}',
                            description: 'remaining tiles',
                          ),
                          StatDisplay(
                            statistic:
                                '${download.prunedTiles} (${download.prunedTiles == 0 ? 0 : (100 - ((download.cachedTiles - download.prunedTiles) / download.cachedTiles) * 100).toStringAsFixed(1)}%)',
                            description: 'pruned tiles (% saving)',
                          ),
                          StatDisplay(
                            statistic:
                                '${(download.prunedSize * 1024).asReadableSize} (${download.prunedTiles == 0 ? 0 : (100 - ((download.cachedSize - download.prunedSize) / download.cachedSize) * 100).toStringAsFixed(1)}%)',
                            description: 'pruned size (% saving)',
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          StatDisplay(
                            statistic: '${download.maxTiles}',
                            description: 'total tiles',
                          ),
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
                                    ]
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
                    download.prunedTiles +
                    download.failedTiles,
                color: Colors.red,
                child: Text(
                  '${download.failedTiles}',
                  style: const TextStyle(color: Colors.black),
                )
              ),
              (
                value: download.cachedTiles + download.prunedTiles,
                color: Colors.yellow,
                child: Text(
                  '${download.prunedTiles}',
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
                    child: Consumer<DownloadProvider>(
                      builder: (context, provider, _) => provider
                              .failedTiles.isEmpty
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
                              itemCount: provider.failedTiles.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: Icon(
                                  switch (provider.failedTiles[index].result) {
                                    TileEventResult.noConnectionDuringFetch =>
                                      Icons.wifi_off,
                                    TileEventResult.unknownFetchException =>
                                      Icons.error,
                                    TileEventResult.negativeFetchResponse =>
                                      Icons.reply,
                                    _ => Icons.abc,
                                  },
                                ),
                                title: Text(provider.failedTiles[index].url),
                                subtitle: Text(
                                  switch (provider.failedTiles[index].result) {
                                    TileEventResult.noConnectionDuringFetch =>
                                      'Failed to establish a connection to the network. Check your Internet connection!',
                                    TileEventResult.unknownFetchException =>
                                      'There was an unknown error when trying to download this tile, of type ${provider.failedTiles[index].fetchError.runtimeType}',
                                    TileEventResult.negativeFetchResponse =>
                                      'The tile server responded with an HTTP status code of ${provider.failedTiles[index].fetchResponse!.statusCode} (${provider.failedTiles[index].fetchResponse!.reasonPhrase})',
                                    _ => '',
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
          /*Stack(
            children: [
              LinearProgressIndicator(
                value: data.percentageProgress / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
              LinearProgressIndicator(
                value: data.persistedTiles / data.maxTiles,
                minHeight: 12,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: data.failedTiles.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_off, size: 36),
                      SizedBox(height: 10),
                      Text('No Failed Tiles'),
                    ],
                  )
                : Row(
                    children: [
                      const SizedBox(width: 30),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          StatDisplay(
                            statistic: data.failedTiles.length.toString(),
                            description: 'failed tiles',
                          ),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: ListView.builder(
                          itemCount: data.failedTiles.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(
                              data.failedTiles[index],
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),*/
        ],
      );
}
