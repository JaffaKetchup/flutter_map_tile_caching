import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'package:stream_transform/stream_transform.dart';

class DownloadStats extends StatelessWidget {
  const DownloadStats({
    Key? key,
    required this.mcm,
    required this.download,
  }) : super(key: key);

  final MapCachingManager? mcm;
  final Stream<DownloadProgress>? download;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<DownloadProgress>(
          stream: download,
          builder: (context, progress) {
            // If connection done and no error, normal
            // If connection not done, show loading
            // If
            if (progress.connectionState == ConnectionState.waiting) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          progress.data!.successfulTiles.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          progress.data!.failedTiles.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: progress.data!.failedTiles.isNotEmpty
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                        Text(
                          'tiles failed',
                          style: TextStyle(
                            color: progress.data!.failedTiles.isNotEmpty
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
                          progress.data!.remainingTiles.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const Text('remaining tiles'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          progress.data!.duration.toString().split('.')[0],
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
                        value: progress.data!.percentageProgress / 100,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(progress.data!.percentageProgress.toStringAsFixed(1) +
                        '%'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                : (size.data! / 1024).toStringAsFixed(2) +
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
                            !length.hasData ? '...' : length.data!.toString(),
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
    );
  }
}
