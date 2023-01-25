import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';

class BufferingConfiguration extends StatelessWidget {
  const BufferingConfiguration({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DownloadProvider>(
        builder: (context, provider, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BUFFERING CONFIGURATION'),
            const SizedBox(height: 15),
            if (provider.regionTiles == null)
              const CircularProgressIndicator()
            else ...[
              Row(
                children: [
                  SegmentedButton<DownloadBufferMode>(
                    segments: const [
                      ButtonSegment(
                        value: DownloadBufferMode.disabled,
                        label: Text('Disabled'),
                        icon: Icon(Icons.cancel),
                      ),
                      ButtonSegment(
                        value: DownloadBufferMode.tiles,
                        label: Text('Tiles'),
                        icon: Icon(Icons.flip_to_front_outlined),
                      ),
                      ButtonSegment(
                        value: DownloadBufferMode.bytes,
                        label: Text('Size (kB)'),
                        icon: Icon(Icons.storage_rounded),
                      ),
                    ],
                    selected: {provider.bufferMode},
                    onSelectionChanged: (s) => provider.bufferMode = s.single,
                  ),
                  const SizedBox(width: 20),
                  provider.bufferMode == DownloadBufferMode.disabled
                      ? const SizedBox.shrink()
                      : Text(
                          provider.bufferMode == DownloadBufferMode.tiles &&
                                  provider.bufferingAmount >=
                                      provider.regionTiles!
                              ? 'Write Once'
                              : '${provider.bufferingAmount} ${provider.bufferMode == DownloadBufferMode.tiles ? 'tiles' : 'kB'}',
                        ),
                ],
              ),
              const SizedBox(height: 5),
              provider.bufferMode == DownloadBufferMode.disabled
                  ? const Slider(value: 0.5, onChanged: null)
                  : Slider(
                      value: provider.bufferMode == DownloadBufferMode.tiles
                          ? provider.bufferingAmount
                              .clamp(10, provider.regionTiles!)
                              .roundToDouble()
                          : provider.bufferingAmount.roundToDouble(),
                      min: provider.bufferMode == DownloadBufferMode.tiles
                          ? 10
                          : 500,
                      max: provider.bufferMode == DownloadBufferMode.tiles
                          ? provider.regionTiles!.toDouble()
                          : 10000,
                      onChanged: (value) =>
                          provider.bufferingAmount = value.round(),
                    ),
            ],
          ],
        ),
      );
}
