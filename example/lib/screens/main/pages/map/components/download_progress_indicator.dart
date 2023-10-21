import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../downloading/state/downloading_provider.dart';
import 'bubble_arrow_painter.dart';
import 'side_indicator_painter.dart';

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({
    super.key,
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 950;

    return Selector<DownloadingProvider, StreamSubscription<DownloadProgress>?>(
      selector: (context, provider) => provider.tilesPreviewStreamSub,
      builder: (context, tpss, child) => isNarrow
          ? AnimatedPositioned(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              bottom: tpss != null ? 20 : -55,
              left: constraints.maxWidth / 2 + constraints.maxWidth / 8 - 85,
              height: 50,
              width: 170,
              child: CustomPaint(
                painter: BubbleArrowIndicator(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.background,
                ),
                child: child,
              ),
            )
          : AnimatedPositioned(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              top: constraints.maxHeight / 2 + 12,
              left: tpss != null ? 8 : -200,
              height: 50,
              width: 180,
              child: CustomPaint(
                painter: SideIndicatorPainter(
                  startRadius: const Radius.circular(8),
                  endRadius: const Radius.circular(25),
                  color: Theme.of(context).colorScheme.background,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: child,
                ),
              ),
            ),
      child: StreamBuilder<DownloadProgress>(
        stream: context.select<DownloadingProvider, Stream<DownloadProgress>?>(
          (provider) => provider.downloadProgress,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator.adaptive(),
              ),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${snapshot.data!.percentageProgress.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox.square(dimension: 12),
              Text(
                '${snapshot.data!.tilesPerSecond.toStringAsPrecision(3)} tps',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
