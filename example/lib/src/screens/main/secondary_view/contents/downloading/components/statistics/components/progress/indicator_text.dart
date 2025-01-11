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
  bool _usePercentages = false;

  @override
  Widget build(BuildContext context) {
    final successfulFlushedTilesCount =
        context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.flushedTilesCount,
    );
    final successfulFlushedTilesSize =
        context.select<DownloadingProvider, double>(
              (p) => p.latestDownloadProgress.flushedTilesSize,
            ) *
            1024;

    final successfulBufferedTilesCount =
        context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.bufferedTilesCount,
    );
    final successfulBufferedTilesSize =
        context.select<DownloadingProvider, double>(
              (p) => p.latestDownloadProgress.bufferedTilesSize,
            ) *
            1024;

    final skippedExistingTilesCount = context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.existingTilesCount,
    );
    final skippedExistingTilesSize =
        context.select<DownloadingProvider, double>(
              (p) => p.latestDownloadProgress.existingTilesSize,
            ) *
            1024;

    final skippedSeaTilesCount = context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.seaTilesCount,
    );
    final skippedSeaTilesSize = context.select<DownloadingProvider, double>(
          (p) => p.latestDownloadProgress.seaTilesSize,
        ) *
        1024;

    final failedNegativeResponseTilesCount =
        context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.negativeResponseTilesCount,
    );

    final failedFailedRequestTilesCount =
        context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.failedRequestTilesCount,
    );

    final retryTilesQueuedCount = context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.retryTilesQueuedCount,
    );

    final remainingTilesCount = context.select<DownloadingProvider, int>(
          (p) => p.latestDownloadProgress.remainingTilesCount,
        ) -
        retryTilesQueuedCount;

    final maxTilesCount = context.select<DownloadingProvider, int>(
      (p) => p.latestDownloadProgress.maxTilesCount,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 12,
          children: [
            Tooltip(
              message: 'Use mask effect',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6) +
                    const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const Icon(Icons.gradient),
                    Switch.adaptive(
                      value: context.select<DownloadingProvider, bool>(
                        (provider) => provider.useMaskEffect,
                      ),
                      onChanged: (val) => context
                          .read<DownloadingProvider>()
                          .useMaskEffect = val,
                    ),
                  ],
                ),
              ),
            ),
            SegmentedButton(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.numbers),
                  tooltip: 'Show tile counts',
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.percent),
                  tooltip: 'Show percentages',
                ),
              ],
              selected: {_usePercentages},
              onSelectionChanged: (v) =>
                  setState(() => _usePercentages = v.single),
              showSelectedIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TextRow(
          color: DownloadingProgressIndicatorColors.successfulColor,
          type: 'Successful',
          statistic: _usePercentages
              ? '''${(((successfulFlushedTilesCount + successfulBufferedTilesCount) / maxTilesCount) * 100).toStringAsFixed(1)}% '''
              : '''${successfulFlushedTilesCount + successfulBufferedTilesCount} tiles (${(successfulFlushedTilesSize + successfulBufferedTilesSize).asReadableSize})''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Flushed',
          statistic: _usePercentages
              ? '''${((successfulFlushedTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}% '''
              : '''$successfulFlushedTilesCount tiles (${successfulFlushedTilesSize.asReadableSize})''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Buffered',
          statistic: _usePercentages
              ? '''${((successfulBufferedTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '''$successfulBufferedTilesCount tiles (${successfulBufferedTilesSize.asReadableSize})''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.skippedColor,
          type: 'Skipped',
          statistic: _usePercentages
              ? '''${(((skippedSeaTilesCount + skippedExistingTilesCount) / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '''${skippedSeaTilesCount + skippedExistingTilesCount} tiles (${(skippedSeaTilesSize + skippedExistingTilesSize).asReadableSize})''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Existing',
          statistic: _usePercentages
              ? '''${((skippedExistingTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '''$skippedExistingTilesCount tiles (${skippedExistingTilesSize.asReadableSize})''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Sea Tiles',
          statistic: _usePercentages
              ? '''${((skippedSeaTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '''$skippedSeaTilesCount tiles (${skippedSeaTilesSize.asReadableSize})''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.failedColor,
          type: 'Failed',
          statistic: _usePercentages
              ? '''${(((failedNegativeResponseTilesCount + failedFailedRequestTilesCount) / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '''${failedNegativeResponseTilesCount + failedFailedRequestTilesCount} tiles''',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Negative Response',
          statistic: _usePercentages
              ? '''${((failedNegativeResponseTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '$failedNegativeResponseTilesCount tiles',
        ),
        const SizedBox(height: 4),
        _TextRow(
          type: 'Failed Request',
          statistic: _usePercentages
              ? '''${((failedFailedRequestTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '$failedFailedRequestTilesCount tiles',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.retryQueueColor,
          type: 'Queued For Retry',
          statistic: _usePercentages
              ? '''${((retryTilesQueuedCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '$retryTilesQueuedCount tiles',
        ),
        const SizedBox(height: 4),
        _TextRow(
          color: DownloadingProgressIndicatorColors.pendingColor,
          type: 'Pending',
          statistic: _usePercentages
              ? '''${((remainingTilesCount / maxTilesCount) * 100).toStringAsFixed(1)}%'''
              : '$remainingTilesCount/$maxTilesCount tiles',
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
