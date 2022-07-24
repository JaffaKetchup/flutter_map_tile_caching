import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/download_provider.dart';
import 'components/header.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({Key? key}) : super(key: key);

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Consumer<DownloadProvider>(
                    builder: (context, provider, _) =>
                        StreamBuilder<DownloadProgress>(
                      stream: provider.downloadProgress,
                      initialData: DownloadProgress.empty(),
                      builder: (context, snapshot) => Column(
                        children: [
                          Row(
                            children: [
                              snapshot.data!.tileImage != null
                                  ? Image(
                                      image: snapshot.data!.tileImage!,
                                      height: 128,
                                      width: 128,
                                      gaplessPlayback: true,
                                    )
                                  : const SizedBox(
                                      height: 128,
                                      width: 128,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${snapshot.data!.successfulTiles} (${snapshot.data!.percentageProgress.round()}%)',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'successful tiles',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    snapshot.data!.maxTiles.toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'total tiles',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    snapshot.data!.duration
                                        .toString()
                                        .split('.')
                                        .first
                                        .padLeft(8, '0'),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'time taken',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    snapshot.data!.estRemainingDuration
                                        .toString()
                                        .split('.')
                                        .first
                                        .padLeft(8, '0'),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'est time remaining',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          LinearProgressIndicator(
                            value: snapshot.data!.percentageProgress / 100,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
