import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';
import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
import 'components/shared/to_config_method.dart';
import 'components/sub_regions_list/components/no_sub_regions.dart';
import 'components/sub_regions_list/sub_regions_list.dart';

class RegionSelectionViewBottomSheet extends StatelessWidget {
  const RegionSelectionViewBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final hasConstructedRegions = context.select<RegionSelectionProvider, bool>(
      (p) => p.constructedRegions.isNotEmpty,
    );

    return CustomScrollView(
      controller:
          BottomSheetScrollableProvider.innerScrollControllerOf(context),
      slivers: [
        const TabHeader(title: 'Download Selection'),
        if (hasConstructedRegions)
          const SubRegionsList()
        else
          const NoSubRegions(),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                        onPressed: () => prepareDownloadConfigView(context),
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
      ],
    );
  }
}
