import 'package:flutter/material.dart';

import '../../layouts/side/components/panel.dart';
import 'components/map/map.dart';
import 'components/stores/stores_list.dart';

class HomeViewSide extends StatefulWidget {
  const HomeViewSide({
    super.key,
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  State<HomeViewSide> createState() => _HomeViewSideState();
}

class _HomeViewSideState extends State<HomeViewSide> {
  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SideViewPanel(child: MapConfigurator()),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                color: Theme.of(context).colorScheme.surface,
              ),
              width: double.infinity,
              height: double.infinity,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 16),
                    sliver: StoresList(
                      useCompactLayout: widget.constraints.maxWidth / 3 < 500,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ),
        ],
      );
}
