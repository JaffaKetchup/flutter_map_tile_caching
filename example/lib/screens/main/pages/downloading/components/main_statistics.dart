import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../state/downloading_provider.dart';
import 'stat_display.dart';

class MainStatistics extends StatefulWidget {
  const MainStatistics({
    super.key,
    required this.download,
    required this.storeDirectory,
  });

  final DownloadProgress download;
  final StoreDirectory storeDirectory;

  @override
  State<MainStatistics> createState() => _MainStatisticsState();
}

class _MainStatisticsState extends State<MainStatistics> {
  @override
  Widget build(BuildContext context) => IntrinsicWidth(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: Text(
                '${widget.download.attemptedTiles}/${widget.download.maxTiles} (${widget.download.percentageProgress.toStringAsFixed(2)}%)',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            StatDisplay(
              statistic:
                  '${widget.download.elapsedDuration.toString().split('.')[0]} / ${widget.download.estTotalDuration.toString().split('.')[0]}',
              description: 'elapsed / estimated total duration',
            ),
            StatDisplay(
              statistic:
                  widget.download.estRemainingDuration.toString().split('.')[0],
              description: 'estimated remaining duration',
            ),
            RepaintBoundary(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.download.tilesPerSecond.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.download.isTPSArtificiallyCapped
                              ? Colors.amber
                              : null,
                        ),
                      ),
                      if (widget.download.isTPSArtificiallyCapped) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock_clock, color: Colors.amber),
                      ],
                    ],
                  ),
                  Text(
                    'approx. tiles per second',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.download.isTPSArtificiallyCapped
                          ? Colors.amber
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!widget.download.isComplete)
              RepaintBoundary(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      onPressed: () async {
                        if (widget.storeDirectory.download.isPaused()) {
                          widget.storeDirectory.download.resume();
                        } else {
                          await widget.storeDirectory.download.pause();
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        widget.storeDirectory.download.isPaused()
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.outlined(
                      onPressed: () => widget.storeDirectory.download.cancel(),
                      icon: const Icon(Icons.cancel),
                    ),
                  ],
                ),
              ),
            if (widget.download.isComplete)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context
                          .read<DownloadingProvider>()
                          .setDownloadProgress(null),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Exit'),
                  ),
                ),
              ),
          ],
        ),
      );
}
