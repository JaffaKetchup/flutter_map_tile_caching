import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';
import '../region_selection/components/sub_regions_list/components/no_sub_regions.dart';
import '../region_selection/components/sub_regions_list/sub_regions_list.dart';

class DownloadConfigurationViewSide extends StatelessWidget {
  const DownloadConfigurationViewSide({super.key});

  @override
  Widget build(BuildContext context) {
    final hasConstructedRegions = context.select<RegionSelectionProvider, bool>(
      (p) => p.constructedRegions.isNotEmpty,
    );

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: Theme.of(context).colorScheme.surface,
            ),
            padding: const EdgeInsets.all(4),
            child: IconButton(
              onPressed: () {
                context
                    .read<RegionSelectionProvider>()
                    .isDownloadSetupPanelVisible = false;
              },
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Return to selection',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
            ),
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: hasConstructedRegions
                          ? const EdgeInsets.only(top: 16, bottom: 16 + 52)
                          : EdgeInsets.zero,
                      sliver: hasConstructedRegions
                          ? const SubRegionsList()
                          : const NoSubRegions(),
                    ),
                  ],
                ),
                PositionedDirectional(
                  end: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    ignoring: !hasConstructedRegions,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      opacity: hasConstructedRegions ? 1 : 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => context
                                      .read<RegionSelectionProvider>()
                                      .clearConstructedRegions(),
                                  icon: const Icon(Icons.delete_forever),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => context
                                        .read<RegionSelectionProvider>()
                                        .isDownloadSetupPanelVisible = true,
                                    label: const Text('Configure Download'),
                                    icon: const Icon(Icons.tune),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
