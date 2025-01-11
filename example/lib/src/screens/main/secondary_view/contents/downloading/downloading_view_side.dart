import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/state/region_selection_provider.dart';
import '../../layouts/side/components/panel.dart';
import 'components/confirm_cancellation_dialog.dart';
import 'components/statistics/statistics.dart';

class DownloadingViewSide extends StatefulWidget {
  const DownloadingViewSide({
    super.key,
  });

  @override
  State<DownloadingViewSide> createState() => _DownloadingViewSideState();
}

class _DownloadingViewSideState extends State<DownloadingViewSide> {
  bool _isPausing = false;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: IconButton(
                    onPressed: () async {
                      if (context.read<DownloadingProvider>().isComplete) {
                        context.read<RegionSelectionProvider>()
                          ..isDownloadSetupPanelVisible = false
                          ..clearConstructedRegions()
                          ..clearCoordinates();
                        context.read<DownloadingProvider>().reset();
                        return;
                      }

                      await showDialog(
                        context: context,
                        builder: (context) => const ConfirmCancellationDialog(),
                      );
                    },
                    icon: const Icon(Icons.cancel),
                    tooltip: 'Cancel Download',
                  ),
                ),
                const SizedBox(width: 12),
                if (context
                    .select<DownloadingProvider, bool>((p) => !p.isComplete))
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: _isPausing
                        ? const AspectRatio(
                            aspectRatio: 1,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                          )
                        : context.select<DownloadingProvider, bool>(
                            (p) => p.isPaused,
                          )
                            ? IconButton(
                                onPressed: () => context
                                    .read<DownloadingProvider>()
                                    .resume(),
                                icon: const Icon(Icons.play_arrow),
                                tooltip: 'Resume Download',
                              )
                            : IconButton(
                                onPressed: () async {
                                  setState(() => _isPausing = true);
                                  await context
                                      .read<DownloadingProvider>()
                                      .pause();
                                  setState(() => _isPausing = false);
                                },
                                icon: const Icon(Icons.pause),
                                tooltip: 'Pause Download',
                              ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: SideViewPanel(
              autoPadding: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: DownloadStatistics(showTitle: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}
