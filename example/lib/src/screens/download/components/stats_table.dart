part of '../download.dart';

class _StatsTable extends StatelessWidget {
  const _StatsTable({
    required this.download,
  });

  final DownloadProgress? download;

  @override
  Widget build(BuildContext context) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              StatDisplay(
                statistic:
                    '${(download?.cachedTiles ?? 0) - (download?.bufferedTiles ?? 0)} + ${download?.bufferedTiles ?? 0}',
                description: 'cached + buffered tiles',
              ),
              StatDisplay(
                statistic:
                    '${(((download?.cachedSize ?? 0) - (download?.bufferedSize ?? 0)) * 1024).asReadableSize} + ${((download?.bufferedSize ?? 0) * 1024).asReadableSize}',
                description: 'cached + buffered size',
              ),
            ],
          ),
          TableRow(
            children: [
              StatDisplay(
                statistic:
                    '${download?.skippedTiles ?? 0} (${(download?.skippedTiles ?? 0) == 0 ? 0 : (100 - (((download?.cachedTiles ?? 0) - (download?.skippedTiles ?? 0)) / (download?.cachedTiles ?? 0)) * 100).clamp(double.minPositive, 100).toStringAsFixed(1)}%)',
                description: 'skipped tiles (% saving)',
              ),
              StatDisplay(
                statistic:
                    '${((download?.skippedSize ?? 0) * 1024).asReadableSize} (${(download?.skippedTiles ?? 0) == 0 ? 0 : (100 - (((download?.cachedSize ?? 0) - (download?.skippedSize ?? 0)) / (download?.cachedSize ?? 0)) * 100).clamp(double.minPositive, 100).toStringAsFixed(1)}%)',
                description: 'skipped size (% saving)',
              ),
            ],
          ),
          TableRow(
            children: [
              RepaintBoundary(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          download?.failedTiles.toString() ?? '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: (download?.failedTiles ?? 0) == 0
                                ? null
                                : Colors.red,
                          ),
                        ),
                        if ((download?.failedTiles ?? 0) != 0) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.warning_amber,
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'failed tiles',
                      style: TextStyle(
                        fontSize: 16,
                        color: (download?.failedTiles ?? 0) == 0
                            ? null
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ],
      );
}
