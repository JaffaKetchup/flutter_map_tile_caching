import 'package:flutter/material.dart';

import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
import 'components/recoverable_regions_list/recoverable_regions_list.dart';

class RecoveryViewBottomSheet extends StatelessWidget {
  const RecoveryViewBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller:
            BottomSheetScrollableProvider.innerScrollControllerOf(context),
        slivers: const [
          TabHeader(title: 'Recovery'),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          RecoverableRegionsList(),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
}
