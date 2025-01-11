import 'package:flutter/material.dart';

import 'components/progress/indicator_bars.dart';
import 'components/progress/indicator_text.dart';
import 'components/tile_display/tile_display.dart';
import 'components/timing/timing.dart';
import 'components/title_bar/title_bar.dart';

class DownloadStatistics extends StatelessWidget {
  const DownloadStatistics({
    super.key,
    required this.showTitle,
  });

  final bool showTitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const TitleBar(),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 6),
          const TimingStats(),
          const SizedBox(height: 24),
          const ProgressIndicatorBars(),
          const SizedBox(height: 16),
          const ProgressIndicatorText(),
          const SizedBox(height: 24),
          const TileDisplay(),
        ],
      );
}
