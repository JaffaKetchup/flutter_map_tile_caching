part of 'download_layout.dart';

class _StatsTable extends StatelessWidget {
  const _StatsTable({
    required this.download,
  });

  final DownloadProgress download;

  @override
  Widget build(BuildContext context) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              StatDisplay(
                statistic:
                    '${download.cachedTiles - download.bufferedTiles} + ${download.bufferedTiles}',
                description: 'cached + buffered tiles',
              ),
              StatDisplay(
                statistic:
                    '${((download.cachedSize - download.bufferedSize) * 1024).asReadableSize} + ${(download.bufferedSize * 1024).asReadableSize}',
                description: 'cached + buffered size',
              ),
            ],
          ),
          TableRow(
            children: [
              StatDisplay(
                statistic:
                    '${download.skippedTiles} (${download.skippedTiles == 0 ? 0 : (100 - ((download.cachedTiles - download.skippedTiles) / download.cachedTiles) * 100).clamp(double.minPositive, 100).toStringAsFixed(1)}%)',
                description: 'skipped tiles (% saving)',
              ),
              StatDisplay(
                statistic:
                    '${(download.skippedSize * 1024).asReadableSize} (${download.skippedTiles == 0 ? 0 : (100 - ((download.cachedSize - download.skippedSize) / download.cachedSize) * 100).clamp(double.minPositive, 100).toStringAsFixed(1)}%)',
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
                          download.failedTiles.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                download.failedTiles == 0 ? null : Colors.red,
                          ),
                        ),
                        if (download.failedTiles != 0) ...[
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
                        color: download.failedTiles == 0 ? null : Colors.red,
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
