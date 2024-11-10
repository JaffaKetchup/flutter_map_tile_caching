import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../shared/state/download_provider.dart';

class TileDisplay extends StatelessWidget {
  const TileDisplay({super.key});

  static const _dimension = 180.0;

  @override
  Widget build(BuildContext context) {
    if (context
            .watch<DownloadingProvider>()
            .latestEvent
            .latestTileEvent
            ?.tileImage
        case final tileImage?) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: _dimension,
            child: Stack(
              children: [
                Image.memory(
                  tileImage,
                  cacheHeight: _dimension.toInt(),
                  cacheWidth: _dimension.toInt(),
                  gaplessPlayback: true,
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
      );
    }

    if (context.watch<DownloadingProvider>().latestEvent.isComplete) {
      return const SizedBox.shrink();
    }

    return const Center(
      child: SizedBox.square(
        dimension: _dimension,
        child: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}
