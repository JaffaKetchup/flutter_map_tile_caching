import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/download_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';
import 'components/progress/indicator_bars.dart';
import 'components/progress/indicator_text.dart';
import 'components/timing/timing.dart';

class DownloadStatistics extends StatelessWidget {
  const DownloadStatistics({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.select<DownloadingProvider, bool>(
            (p) => p.latestEvent.isComplete,
          ))
            IntrinsicHeight(
              child: Row(
                children: [
                  Text(
                    'Downloading complete',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  SizedBox(
                    height: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<RegionSelectionProvider>()
                          ..isDownloadSetupPanelVisible = false
                          ..clearConstructedRegions()
                          ..clearCoordinates();
                        context.read<DownloadingProvider>().reset();
                      },
                      label: const Text('Reset'),
                      icon: const Icon(Icons.done_all),
                    ),
                  ),
                ],
              ),
            )
          else if (context.select<DownloadingProvider, bool>((p) => p.isPaused))
            Row(
              children: [
                Text(
                  'Downloading paused',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                const Icon(Icons.pause_circle, size: 36),
              ],
            )
          else
            Row(
              children: [
                Text(
                  'Downloading map',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(2),
                  child: SizedBox.square(
                    dimension: 32,
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          const TimingStats(),
          const SizedBox(height: 24),
          const ProgressIndicatorBars(),
          const SizedBox(height: 16),
          const ProgressIndicatorText(),
        ],
      );
}
