import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'stat_display.dart';

class VerticalLayout extends StatelessWidget {
  const VerticalLayout({
    Key? key,
    required this.data,
  }) : super(key: key);

  final DownloadProgress data;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatDisplay(
                largeText:
                    '${data.successfulTiles} / ${data.maxTiles} (${data.percentageProgress.toStringAsFixed(2)}%)',
                smallText: 'successful / total tiles',
              ),
              const SizedBox(height: 2),
              StatDisplay(
                largeText: data.tilesPerSecond.round().toString(),
                smallText: 'tiles per second',
              ),
              const SizedBox(height: 2),
              StatDisplay(
                largeText:
                    data.duration.toString().split('.').first.padLeft(8, '0'),
                smallText: 'duration taken',
              ),
              const SizedBox(height: 2),
              StatDisplay(
                largeText: data.estRemainingDuration
                    .toString()
                    .split('.')
                    .first
                    .padLeft(8, '0'),
                smallText: 'est remaining duration',
              ),
              const SizedBox(height: 2),
              StatDisplay(
                largeText: data.estTotalDuration
                    .toString()
                    .split('.')
                    .first
                    .padLeft(8, '0'),
                smallText: 'est total duration',
              ),
              const SizedBox(height: 2),
              StatDisplay(
                largeText:
                    '${data.existingTiles} (${data.existingTilesDiscount.ceil()}%) | ${data.seaTiles} (${data.seaTilesDiscount.ceil()}%)',
                smallText: 'existing tiles | sea tiles',
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: data.percentageProgress / 100,
            minHeight: 8,
          ),
          const SizedBox(height: 15),
          Expanded(
            child: data.failedTiles.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.report_off, size: 36),
                      SizedBox(height: 10),
                      Text('No Failed Tiles'),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.failedTiles.length.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'failed tiles',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(index.toString()),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
}
