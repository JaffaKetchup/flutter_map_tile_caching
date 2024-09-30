import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../shared/misc/exts/size_formatter.dart';
import 'components/confirm_cancellation_dialog.dart';
import 'components/main_statistics.dart';
import 'components/multi_linear_progress_indicator.dart';
import 'components/stat_display.dart';

part 'components/stats_table.dart';

class DownloadPopup extends StatefulWidget {
  const DownloadPopup({super.key});

  static const String route = '/download/progress';

  @override
  State<DownloadPopup> createState() => _DownloadPopupState();
}

class _DownloadPopupState extends State<DownloadPopup> {
  bool isInitialised = false;

  late final Stream<DownloadProgress> downloadProgress;
  late final StreamSubscription<DownloadProgress> dpSubscription;
  late final int maxTiles;

  final failedTiles = <TileEvent>[];
  final skippedTiles = <TileEvent>[];
  bool isCompleteCanPop = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isInitialised) {
      final arguments = ModalRoute.of(context)!.settings.arguments! as ({
        Stream<DownloadProgress> downloadProgress,
        int maxTiles
      });
      downloadProgress = arguments.downloadProgress.asBroadcastStream();
      dpSubscription = downloadProgress.listen((progress) {
        if (progress.latestTileEvent.isRepeat) return;
        if (progress.latestTileEvent.result.category ==
            TileEventResultCategory.failed) {
          failedTiles.add(progress.latestTileEvent);
        }
        if (progress.latestTileEvent.result.category ==
            TileEventResultCategory.skipped) {
          skippedTiles.add(progress.latestTileEvent);
        }
        isCompleteCanPop = progress.isComplete;
      });
      maxTiles = arguments.maxTiles;
    }

    isInitialised = true;
  }

  @override
  void dispose() {
    dpSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: isCompleteCanPop,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop &&
              await showDialog(
                context: context,
                builder: (context) => const ConfirmCancellationDialog(),
              ) as bool &&
              context.mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Downloading Region'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder(
              stream: downloadProgress,
              builder: (context, snapshot) {
                final download = snapshot.data;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Flex(
                              direction:
                                  isWide ? Axis.horizontal : Axis.vertical,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    runAlignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 32,
                                    runSpacing: 28,
                                    children: [
                                      RepaintBoundary(
                                        child: SizedBox.square(
                                          dimension: isWide ? 216 : 196,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: download?.latestTileEvent
                                                        .tileImage !=
                                                    null
                                                ? Image.memory(
                                                    download!.latestTileEvent
                                                        .tileImage!,
                                                    gaplessPlayback: true,
                                                  )
                                                : const Center(
                                                    child:
                                                        CircularProgressIndicator
                                                            .adaptive(),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      MainStatistics(
                                        download: download,
                                        maxTiles: maxTiles,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox.square(dimension: 16),
                                if (isWide)
                                  const VerticalDivider()
                                else
                                  const Divider(),
                                const SizedBox.square(dimension: 16),
                                if (isWide)
                                  Expanded(
                                    child: _StatsTable(download: download),
                                  )
                                else
                                  _StatsTable(download: download),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          MulitLinearProgressIndicator(
                            maxValue: maxTiles,
                            backgroundChild: Text(
                              '${download?.remainingTiles ?? 0}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            progresses: [
                              (
                                value: (download?.cachedTiles ?? 0) +
                                    (download?.skippedTiles ?? 0) +
                                    (download?.failedTiles ?? 0),
                                color: Colors.red,
                                child: Text(
                                  '${download?.failedTiles ?? 0}',
                                  style: const TextStyle(color: Colors.black),
                                )
                              ),
                              (
                                value: (download?.cachedTiles ?? 0) +
                                    (download?.skippedTiles ?? 0),
                                color: Colors.yellow,
                                child: Text(
                                  '${download?.skippedTiles ?? 0}',
                                  style: const TextStyle(color: Colors.black),
                                )
                              ),
                              (
                                value: download?.cachedTiles ?? 0,
                                color: Colors.green[300]!,
                                child: Text(
                                  '${download?.bufferedTiles ?? 0}',
                                  style: const TextStyle(color: Colors.black),
                                )
                              ),
                              (
                                value: (download?.cachedTiles ?? 0) -
                                    (download?.bufferedTiles ?? 0),
                                color: Colors.green,
                                child: Text(
                                  '${(download?.cachedTiles ?? 0) - (download?.bufferedTiles ?? 0)}',
                                  style: const TextStyle(color: Colors.black),
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  'FAILED TILES',
                                ),
                              ),
                              Expanded(
                                child: RepaintBoundary(
                                  child: failedTiles.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
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
                                        )
                                      : ListView.builder(
                                          reverse: true,
                                          addRepaintBoundaries: false,
                                          itemCount: failedTiles.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) =>
                                              ListTile(
                                            leading: Icon(
                                              switch (
                                                  failedTiles[index].result) {
                                                TileEventResult
                                                      .noConnectionDuringFetch =>
                                                  Icons.wifi_off,
                                                TileEventResult
                                                      .unknownFetchException =>
                                                  Icons.error,
                                                TileEventResult
                                                      .negativeFetchResponse =>
                                                  Icons.reply,
                                                _ => Icons.abc,
                                              },
                                            ),
                                            title: Text(failedTiles[index].url),
                                            subtitle: Text(
                                              switch (
                                                  failedTiles[index].result) {
                                                TileEventResult
                                                      .noConnectionDuringFetch =>
                                                  'Failed to establish a connection to the network',
                                                TileEventResult
                                                      .unknownFetchException =>
                                                  'There was an unknown error when trying to download this tile, of type ${failedTiles[index].fetchError.runtimeType}',
                                                TileEventResult
                                                      .negativeFetchResponse =>
                                                  'The tile server responded with an HTTP status code of ${failedTiles[index].fetchResponse!.statusCode} (${failedTiles[index].fetchResponse!.reasonPhrase})',
                                                _ => throw Error(),
                                              },
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  'SKIPPED TILES',
                                ),
                              ),
                              Expanded(
                                child: RepaintBoundary(
                                  child: skippedTiles.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
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
                                        )
                                      : ListView.builder(
                                          reverse: true,
                                          addRepaintBoundaries: false,
                                          itemCount: skippedTiles.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) =>
                                              ListTile(
                                            leading: Icon(
                                              switch (
                                                  skippedTiles[index].result) {
                                                TileEventResult
                                                      .alreadyExisting =>
                                                  Icons.disabled_visible,
                                                TileEventResult.isSeaTile =>
                                                  Icons.water_drop,
                                                _ => Icons.abc,
                                              },
                                            ),
                                            title:
                                                Text(skippedTiles[index].url),
                                            subtitle: Text(
                                              switch (
                                                  skippedTiles[index].result) {
                                                TileEventResult
                                                      .alreadyExisting =>
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
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
}
