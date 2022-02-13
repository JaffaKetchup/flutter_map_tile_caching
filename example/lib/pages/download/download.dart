import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../state/bulk_download_provider.dart';
import '../../state/general_provider.dart';
import 'components/exit_dialog.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  MapCachingManager? mcm;
  StorageCachingTileProvider? tileProvider;
  Stream<DownloadProgress>? download;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager?;
    final String? mapSource = context
        .read<GeneralProvider>()
        .persistent!
        .getString('${mcm!.storeName}: sourceURL');

    final BulkDownloadProvider bdp = context.read<BulkDownloadProvider>();

    tileProvider ??= StorageCachingTileProvider.fromMapCachingManager(mcm!);
    download ??= tileProvider!
        .downloadRegion(bdp.region.toDownloadable(
          bdp.minZoom,
          bdp.maxZoom,
          TileLayerOptions(
              urlTemplate: mapSource ??
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
          parallelThreads: bdp.parallelThreads,
          preventRedownload: bdp.preventRedownload,
          seaTileRemoval: bdp.seaTileRemoval,
        ))
        .asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Use exit button to cancel download'),
        ));
        return false;
      },
      child: Consumer<BulkDownloadProvider>(
        builder: (context, bdp, _) {
          if (download == null) {
            return Container(color: Colors.white);
          }

          return Scaffold(
              appBar: AppBar(
                title: const Text('Downloading...'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    if ((await showDialog<bool>(
                          context: context,
                          builder: (context) => const ExitDialog(),
                        )) ??
                        false) {
                      tileProvider!.cancelDownload();
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      StreamBuilder<DownloadProgress>(
                        stream: download,
                        builder: (context, progress) {
                          if (!progress.hasData) {
                            return SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text(
                                    'Preparing your download...\nPlease wait, this may take a while.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.successfulTiles
                                            .toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const Text('tiles downloaded'),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.failedTiles.length
                                            .toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                          color: progress
                                                  .data!.failedTiles.isNotEmpty
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'tiles failed',
                                        style: TextStyle(
                                          color: progress
                                                  .data!.failedTiles.isNotEmpty
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.maxTiles.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const Text('est. tiles'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.duration
                                            .toString()
                                            .split('.')[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const Text('duration taken'),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.estRemainingDuration
                                            .toString()
                                            .split('.')[0]
                                            .toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const Text('est. remaining duration'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: progress.data!.percentageProgress /
                                          100,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(progress.data!.percentageProgress
                                          .toStringAsFixed(1) +
                                      '%'),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.existingTiles.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const Text('existing tiles'),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        progress.data!.seaTiles.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const Text('sea tiles'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<DownloadProgress>(
                        stream: download!.audit(const Duration(seconds: 1)),
                        builder: (context, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FutureBuilder<double>(
                                      future: mcm!.storeSizeAsync,
                                      builder: (context, size) {
                                        return Text(
                                          !size.hasData
                                              ? '...'
                                              : (size.data! / 1024)
                                                      .toStringAsFixed(2) +
                                                  ' MB',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                          ),
                                        );
                                      }),
                                  const Text('total store size'),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FutureBuilder<int>(
                                      future: mcm!.storeLengthAsync,
                                      builder: (context, length) {
                                        return Text(
                                          !length.hasData
                                              ? '...'
                                              : length.data!.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                          ),
                                        );
                                      }),
                                  const Text('total store length'),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }
}
