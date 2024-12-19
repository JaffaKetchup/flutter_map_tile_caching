import 'package:flutter/material.dart';

import 'components/progress/indicator_bars.dart';
import 'components/progress/indicator_text.dart';
import 'components/tile_display/tile_display.dart';
import 'components/timing/timing.dart';
import 'components/title_bar/title_bar.dart';

class DownloadStatistics extends StatelessWidget {
  const DownloadStatistics({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleBar(),
          SizedBox(height: 24),
          TimingStats(),
          SizedBox(height: 24),
          ProgressIndicatorBars(),
          SizedBox(height: 16),
          ProgressIndicatorText(),
          SizedBox(height: 24),
          TileDisplay(),
        ],
      );
}
