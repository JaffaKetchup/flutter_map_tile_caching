import 'package:flutter/material.dart';

import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/bottom_sheet_top_spacer.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
import 'components/shape_selector/shape_selector.dart';
import 'components/sub_regions_list/sub_regions_list.dart';

class RegionSelectionViewBottomSheet extends StatelessWidget {
  const RegionSelectionViewBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller:
            BottomSheetScrollableProvider.innerScrollControllerOf(context),
        slivers: const [
          BottomSheetTopSpacer(),
          TabHeader(title: 'Download Selection'),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: ShapeSelector(),
            ),
          ),
          SliverToBoxAdapter(child: Divider(height: 24)),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          SubRegionsList(),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverToBoxAdapter(child: Divider(height: 24)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: ShapeSelector(),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
}
