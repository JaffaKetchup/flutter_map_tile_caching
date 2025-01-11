import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../shared/state/download_provider.dart';
import '../../../../../../../../../shared/state/region_selection_provider.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.select<DownloadingProvider, bool>((p) => p.isComplete)) {
      return IntrinsicHeight(
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
      );
    }
    if (context.select<DownloadingProvider, bool>((p) => p.isPaused)) {
      return Row(
        children: [
          Text(
            'Downloading paused',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          const Icon(Icons.pause_circle, size: 36),
        ],
      );
    } else {
      return Row(
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
      );
    }
  }
}
