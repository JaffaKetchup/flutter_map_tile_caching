import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stream_transform/stream_transform.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class DownloadStats extends StatefulWidget {
  const DownloadStats({
    Key? key,
    required this.mcm,
    required this.download,
  }) : super(key: key);

  final MapCachingManager? mcm;
  final Stream<DownloadProgress>? download;

  @override
  State<DownloadStats> createState() => _DownloadStatsState();
}

class _DownloadStatsState extends State<DownloadStats> {
  final http.Client httpClient = http.Client();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<DownloadProgress>(
          stream: widget.download,
          builder: (context, progress) {
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

            if (progress.hasError) {
              return SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 56,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Error Starting Download',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'There was an error whilst starting the download.\n\n${progress.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Exit'),
                    ),
                    const SizedBox(height: 50),
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
                        const Text('tiles downloaded'),
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
          stream: widget.download!.audit(const Duration(seconds: 1)),
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<double>(
                        future: widget.mcm!.storeSizeAsync,
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
                        future: widget.mcm!.storeLengthAsync,
                        builder: (context, length) {
                          return Text(
                            !length.hasData
                                ? '...'
                                : (length.data! - 1)
                                    .clamp(0, double.infinity)
                                    .toString(),
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
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        const Text(
          'Did You Know?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        StreamBuilder<void>(
          stream: Stream.periodic(const Duration(seconds: 20)),
          builder: (context, _) {
            return FutureBuilder<http.Response>(
              future: httpClient
                  .get(Uri.parse('http://numbersapi.com/random/trivia')),
              builder: (context, response) {
                late final String fact;
                if (!response.hasData) {
                  fact =
                      'A random number fact will appear here every 20 seconds - if you have an Internet connection. Isn\'t that amazing!';
                } else {
                  fact = response.data!.body + ' - Thanks to numbersapi.com';
                }

                return Text(
                  fact,
                  textAlign: TextAlign.center,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
