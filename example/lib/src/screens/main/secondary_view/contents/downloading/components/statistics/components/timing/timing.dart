import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../shared/state/download_configuration_provider.dart';
import '../../../../../../../../../shared/state/download_provider.dart';

class TimingStats extends StatefulWidget {
  const TimingStats({super.key});

  @override
  State<TimingStats> createState() => _TimingStatsState();
}

class _TimingStatsState extends State<TimingStats> {
  @override
  Widget build(BuildContext context) {
    final estRemainingDuration = context.select<DownloadingProvider, Duration>(
      (p) => p.latestDownloadProgress.estRemainingDuration,
    );

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDuration(
                    context.select<DownloadingProvider, Duration>(
                      (p) => p.latestDownloadProgress.elapsedDuration,
                    ),
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('duration elapsed'),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      context
                          .select<DownloadingProvider, double>(
                            (p) => p.latestDownloadProgress.tilesPerSecond,
                          )
                          .toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (context.select<DownloadingProvider, double>(
                          (p) => p.latestDownloadProgress.tilesPerSecond,
                        ) >=
                        context.select<DownloadConfigurationProvider, int>(
                              (p) => p.rateLimit,
                            ) -
                            2)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.publish,
                          color: Colors.orange[700],
                        ),
                      ),
                  ],
                ),
                const Text('tiles per second'),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.speed, size: 32),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.timelapse, size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (estRemainingDuration) {
                    <= Duration.zero => 'almost done',
                    < const Duration(minutes: 1) => '< 1 min',
                    < const Duration(minutes: 60) =>
                      'about ${estRemainingDuration.inMinutes} mins',
                    _ => 'about ${estRemainingDuration.inHours} hours',
                  },
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('est. duration remaining'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(
    Duration duration, {
    bool showSeconds = true,
  }) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '${hours}h ${minutes}m${showSeconds ? ' ${seconds}s' : ''}';
  }
}
