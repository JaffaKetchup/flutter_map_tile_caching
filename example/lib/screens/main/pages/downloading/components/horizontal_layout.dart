import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../../shared/vars/size_formatter.dart';
import 'stat_display.dart';
import 'tile_image.dart';

class HorizontalLayout extends StatelessWidget {
  const HorizontalLayout({
    super.key,
    required this.data,
  });

  final DownloadProgress data;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              tileImage(data: data),
              const SizedBox(width: 15),
              Column(
                children: [
                  StatDisplay(
                    statistic: data.bufferMode == DownloadBufferMode.disabled
                        ? data.successfulTiles.toString()
                        : '${data.successfulTiles} (${data.successfulTiles - data.persistedTiles})',
                    description: 'successful tiles',
                  ),
                  const SizedBox(height: 5),
                  StatDisplay(
                    statistic: data.bufferMode == DownloadBufferMode.disabled
                        ? (data.successfulSize * 1024).asReadableSize
                        : '${(data.successfulSize * 1024).asReadableSize} (${((data.successfulSize - data.persistedSize) * 1024).asReadableSize})',
                    description: 'successful size',
                  ),
                  const SizedBox(height: 5),
                  StatDisplay(
                    statistic: data.maxTiles.toString(),
                    description: 'total tiles',
                  ),
                ],
              ),
              const SizedBox(width: 30),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatDisplay(
                    statistic: data.averageTPS.toStringAsFixed(2),
                    description: 'average tps',
                  ),
                  const SizedBox(height: 5),
                  StatDisplay(
                    statistic: data.duration
                        .toString()
                        .split('.')
                        .first
                        .padLeft(8, '0'),
                    description: 'duration taken',
                  ),
                  const SizedBox(height: 5),
                  StatDisplay(
                    statistic: data.estRemainingDuration
                        .toString()
                        .split('.')
                        .first
                        .padLeft(8, '0'),
                    description: 'est remaining duration',
                  ),
                ],
              ),
              const SizedBox(width: 30),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatDisplay(
                    statistic:
                        '${data.existingTiles} (${data.existingTilesDiscount.ceil()}%)',
                    description: 'existing tiles',
                  ),
                  const SizedBox(height: 5),
                  StatDisplay(
                    statistic:
                        '${data.seaTiles} (${data.seaTilesDiscount.ceil()}%)',
                    description: 'sea tiles',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
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
          ),
        ],
      );
}
