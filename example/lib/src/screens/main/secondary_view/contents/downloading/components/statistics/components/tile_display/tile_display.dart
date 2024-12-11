import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../shared/state/download_provider.dart';

class TileDisplay extends StatelessWidget {
  const TileDisplay({super.key});

  static const _dimension = 200.0;

  @override
  Widget build(BuildContext context) {
    if (context.watch<DownloadingProvider>().isComplete) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 2, color: Theme.of(context).dividerColor),
          ),
          child: SizedBox.square(
            dimension: _dimension,
            child: Stack(
              children: [
                if (context.watch<DownloadingProvider>().latestTileEvent ==
                    null)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (context.watch<DownloadingProvider>().latestTileEvent
                    case final TileEventImage tile)
                  Image.memory(
                    tile.tileImage,
                    cacheHeight: _dimension.toInt(),
                    cacheWidth: _dimension.toInt(),
                    gaplessPlayback: true,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          context.watch<DownloadingProvider>().latestTileEvent
                                  is FailedRequestTileEvent
                              ? Icons
                                  .signal_wifi_connected_no_internet_4_outlined
                              : Icons
                                  .signal_cellular_connected_no_internet_4_bar_outlined,
                          size: 48,
                          color: Colors.red,
                        ),
                        Text(
                          context.watch<DownloadingProvider>().latestTileEvent
                                  is FailedRequestTileEvent
                              ? 'Failed request'
                              : 'Negative response',
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(255 ~/ 2),
                    ),
                    child: const Center(
                      child: Text(
                        'Latest tile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
