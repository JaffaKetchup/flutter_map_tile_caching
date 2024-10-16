import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../shared/state/download_provider.dart';
import 'colors.dart';

class ProgressIndicatorBars extends StatelessWidget {
  const ProgressIndicatorBars({super.key});

  static const double _barHeight = 14;

  @override
  Widget build(BuildContext context) {
    final successful = context.select<DownloadingProvider, double>(
      (p) => p.latestEvent.successfulTiles / p.latestEvent.maxTiles,
    );
    final skipped = context.select<DownloadingProvider, double>(
      (p) => p.latestEvent.skippedTiles / p.latestEvent.maxTiles,
    );
    final failed = context.select<DownloadingProvider, double>(
      (p) => p.latestEvent.failedTiles / p.latestEvent.maxTiles,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            LinearProgressIndicator(
              value: successful + skipped + failed,
              backgroundColor: DownloadingProgressIndicatorColors.pendingColor,
              color: DownloadingProgressIndicatorColors.failedColor,
              minHeight: _barHeight,
            ),
            LinearProgressIndicator(
              value: successful + skipped,
              backgroundColor: Colors.transparent,
              color: DownloadingProgressIndicatorColors.skippedColor,
              minHeight: _barHeight,
            ),
            LinearProgressIndicator(
              value: successful,
              backgroundColor: Colors.transparent,
              color: DownloadingProgressIndicatorColors.successfulColor,
              minHeight: _barHeight,
            ),
          ],
        ),
      ),
    );
  }
}
