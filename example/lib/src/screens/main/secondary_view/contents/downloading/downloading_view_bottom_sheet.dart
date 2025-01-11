import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/state/region_selection_provider.dart';
import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
import 'components/confirm_cancellation_dialog.dart';
import 'components/statistics/statistics.dart';

class DownloadingViewBottomSheet extends StatefulWidget {
  const DownloadingViewBottomSheet({
    super.key,
  });

  @override
  State<DownloadingViewBottomSheet> createState() =>
      _DownloadingViewBottomSheetState();
}

class _DownloadingViewBottomSheetState
    extends State<DownloadingViewBottomSheet> {
  bool _isPausing = false;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller:
            BottomSheetScrollableProvider.innerScrollControllerOf(context),
        slivers: [
          if (context.select<DownloadingProvider, bool>((p) => p.isComplete))
            const TabHeader(title: 'Download Complete')
          else if (context.select<DownloadingProvider, bool>((p) => p.isPaused))
            const TabHeader(title: 'Download Paused')
          else
            const TabHeader(title: 'Downloading Map'),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4) +
                  const EdgeInsets.symmetric(horizontal: 8),
              child: context
                      .select<DownloadingProvider, bool>((p) => p.isComplete)
                  ? Align(
                      alignment: Alignment.centerRight,
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
                    )
                  : IntrinsicHeight(
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              if (context
                                  .read<DownloadingProvider>()
                                  .isComplete) {
                                context.read<RegionSelectionProvider>()
                                  ..isDownloadSetupPanelVisible = false
                                  ..clearConstructedRegions()
                                  ..clearCoordinates();
                                context.read<DownloadingProvider>().reset();
                                return;
                              }

                              await showDialog(
                                context: context,
                                builder: (context) =>
                                    const ConfirmCancellationDialog(),
                              );
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                          ),
                          const Spacer(),
                          if (context.select<DownloadingProvider, bool>(
                            (p) => !p.isComplete,
                          ))
                            _isPausing
                                ? const AspectRatio(
                                    aspectRatio: 1,
                                    child: Center(
                                      child: SizedBox.square(
                                        dimension: 24,
                                        child: CircularProgressIndicator
                                            .adaptive(),
                                      ),
                                    ),
                                  )
                                : context.select<DownloadingProvider, bool>(
                                    (p) => p.isPaused,
                                  )
                                    ? TextButton.icon(
                                        onPressed: () {
                                          context
                                              .read<DownloadingProvider>()
                                              .resume();
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Resume'),
                                      )
                                    : TextButton.icon(
                                        onPressed: () async {
                                          setState(() => _isPausing = true);
                                          await context
                                              .read<DownloadingProvider>()
                                              .pause();
                                          setState(() => _isPausing = false);
                                        },
                                        icon: const Icon(Icons.pause),
                                        label: const Text('Pause'),
                                      ),
                        ],
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8) +
                  const EdgeInsets.symmetric(horizontal: 16),
              child: const DownloadStatistics(showTitle: false),
            ),
          ),
        ],
      );
}
