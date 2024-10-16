import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../../../../../shared/state/download_provider.dart';
import 'colors.dart';

class ProgressIndicatorText extends StatefulWidget {
  const ProgressIndicatorText({super.key});

  @override
  State<ProgressIndicatorText> createState() => _ProgressIndicatorTextState();
}

class _ProgressIndicatorTextState extends State<ProgressIndicatorText> {
  late final Timer _rawPercentAlternator;
  bool _usePercentages = false;

  @override
  void initState() {
    super.initState();
    _rawPercentAlternator = Timer.periodic(
      const Duration(seconds: 2),
      (_) => setState(() => _usePercentages = !_usePercentages),
    );
  }

  @override
  void dispose() {
    _rawPercentAlternator.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cachedTilesCount = context.select<DownloadingProvider, int>(
      (p) => p.latestEvent.cachedTiles - p.latestEvent.bufferedTiles,
    );
    final cachedTilesSize = context.select<DownloadingProvider, double>(
          (p) => p.latestEvent.cachedSize - p.latestEvent.bufferedSize,
        ) *
        1024;

    final bufferedTilesCount = context
        .select<DownloadingProvider, int>((p) => p.latestEvent.bufferedTiles);
    final bufferedTilesSize = context.select<DownloadingProvider, double>(
          (p) => p.latestEvent.bufferedSize,
        ) *
        1024;

    final skippedExistingTilesCount = context
        .select<DownloadingProvider, int>((p) => p.skippedExistingTileCount);
    final skippedExistingTilesSize = context
        .select<DownloadingProvider, int>((p) => p.skippedExistingTileSize);

    final skippedSeaTilesCount =
        context.select<DownloadingProvider, int>((p) => p.skippedSeaTileCount);
    final skippedSeaTilesSize =
        context.select<DownloadingProvider, int>((p) => p.skippedSeaTileSize);

    final failedTilesCount = context
        .select<DownloadingProvider, int>((p) => p.latestEvent.failedTiles);

    final pendingTilesCount = context
        .select<DownloadingProvider, int>((p) => p.latestEvent.remainingTiles);

    final maxTilesCount =
        context.select<DownloadingProvider, int>((p) => p.latestEvent.maxTiles);

    return Column(
      children: [
        _TextRow(
          color: DownloadingProgressIndicatorColors.successfulColor,
          type: 'Successful',
          statistic: _usePercentages
              ? '${(((cachedTilesCount + bufferedTilesCount) / maxTilesCount) * 100).toStringAsFixed(1)}% '
              : '${cachedTilesCount + bufferedTilesCount} tiles (${(cachedTilesSize + bufferedTilesSize).asReadableSize})',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Cached',
          statistic: _usePercentages
              ? '${((cachedTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}% '
              : '$cachedTilesCount tiles (${cachedTilesSize.asReadableSize})',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Buffered',
          statistic: _usePercentages
              ? '${((bufferedTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'
              : '$bufferedTilesCount tiles (${bufferedTilesSize.asReadableSize})',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.skippedColor,
          type: 'Skipped',
          statistic: _usePercentages
              ? '${(((skippedSeaTilesCount + skippedExistingTilesCount) / maxTilesCount) * 100).toStringAsFixed(1)}%'
              : '${skippedSeaTilesCount + skippedExistingTilesCount} tiles (${(skippedSeaTilesSize + skippedExistingTilesSize).asReadableSize})',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Existing',
          statistic: _usePercentages
              ? '${((skippedExistingTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'
              : '$skippedExistingTilesCount tiles (${skippedExistingTilesSize.asReadableSize})',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Sea Tiles',
          statistic: _usePercentages
              ? '${((skippedSeaTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'
              : '$skippedSeaTilesCount tiles (${skippedSeaTilesSize.asReadableSize})',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.failedColor,
          type: 'Failed',
          statistic: _usePercentages
              ? '${((failedTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'
              : '$failedTilesCount tiles',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.pendingColor,
          type: 'Pending',
          statistic: _usePercentages
              ? '${((pendingTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'
              : '$pendingTilesCount/$maxTilesCount tiles',
        ),
      ],
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    this.color,
    required this.type,
    required this.statistic,
  });

  final Color? color;
  final String type;
  final String statistic;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (color case final color?)
            Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else
            const SizedBox(width: 28),
          const SizedBox(width: 8),
          Text(
            type,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontStyle:
                      color == null ? FontStyle.italic : FontStyle.normal,
                ),
          ),
          const Spacer(),
          Text(
            statistic,
            style: TextStyle(
              fontStyle: color == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      );
}
