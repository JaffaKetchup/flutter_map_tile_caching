import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/exts/size_formatter.dart';
import '../state/downloading_provider.dart';
import 'main_statistics.dart';
import 'multi_linear_progress_indicator.dart';
import 'stat_display.dart';

part 'stats_table.dart';

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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return SingleChildScrollView(
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    children: [
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 32,
                          runSpacing: 28,
                          children: [
                            RepaintBoundary(
                              child: SizedBox.square(
                                dimension: isWide ? 216 : 196,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: download.latestTileEvent.tileImage !=
                                          null
                                      ? Image.memory(
                                          download.latestTileEvent.tileImage!,
                                          gaplessPlayback: true,
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator
                                              .adaptive(),
                                        ),
                                ),
                              ),
                            ),
                            MainStatistics(
                              download: download,
                              storeDirectory: storeDirectory,
                              moveToMapPage: moveToMapPage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox.square(dimension: 16),
                      if (isWide) const VerticalDivider() else const Divider(),
                      const SizedBox.square(dimension: 16),
                      if (isWide)
                        Expanded(child: _StatsTable(download: download))
                      else
                        _StatsTable(download: download),
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
                Row(
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
                          builder: (context, failedTiles, _) {
                            final hasFailedTiles = failedTiles.isEmpty;
                            if (hasFailedTiles) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  children: [
                                    Icon(Icons.task_alt, size: 48),
                                    SizedBox(height: 10),
                                    Text(
                                      'Any failed tiles will appear here',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              reverse: true,
                              addRepaintBoundaries: false,
                              itemCount: failedTiles.length,
                              shrinkWrap: true,
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
                            );
                          },
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
                          selector: (context, provider) =>
                              provider.skippedTiles,
                          builder: (context, skippedTiles, _) {
                            final hasSkippedTiles = skippedTiles.isEmpty;
                            if (hasSkippedTiles) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  children: [
                                    Icon(Icons.task_alt, size: 48),
                                    SizedBox(height: 10),
                                    Text(
                                      'Any skipped tiles will appear here',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              addRepaintBoundaries: false,
                              itemCount: skippedTiles.length,
                              shrinkWrap: true,
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
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
