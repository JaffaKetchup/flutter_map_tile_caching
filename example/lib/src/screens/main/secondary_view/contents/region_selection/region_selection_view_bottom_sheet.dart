import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';
import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
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
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        SliverPadding(
          padding: hasConstructedRegions
              ? const EdgeInsets.only(bottom: 16 + 52)
              : EdgeInsets.zero,
          sliver: hasConstructedRegions
              ? const SubRegionsList()
              : const NoSubRegions(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
      ],
    );
  }
}
