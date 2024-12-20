import 'package:flutter/material.dart';

import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
import 'components/map_configurator/map_configurator.dart';
import 'components/stores_list/stores_list.dart';

class HomeViewBottomSheet extends StatefulWidget {
  const HomeViewBottomSheet({super.key});

  @override
  State<HomeViewBottomSheet> createState() => _HomeViewBottomSheetState();
}

class _HomeViewBottomSheetState extends State<HomeViewBottomSheet> {
  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller:
            BottomSheetScrollableProvider.innerScrollControllerOf(context),
        slivers: const [
          TabHeader(title: 'Stores & Config'),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: MapConfigurator()),
          ),
          SliverToBoxAdapter(child: Divider(height: 24)),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          StoresList(useCompactLayout: true),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
}
