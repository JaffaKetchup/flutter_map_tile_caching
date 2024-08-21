import 'package:flutter/material.dart';

import '../../panels/map/map.dart';
import '../../panels/stores/stores_list.dart';

class ConfigViewSide extends StatelessWidget {
  const ConfigViewSide({
    super.key,
    required this.selectedTab,
    required this.constraints,
  });

  final int selectedTab;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => SizeTransition(
          axis: Axis.horizontal,
          axisAlignment: 1, // Align right
          sizeFactor: animation,
          child: child,
        ),
        child: selectedTab == 0
            ? _ContentPanels(constraints)
            : const SizedBox.shrink(),
      );
}

class _ContentPanels extends StatelessWidget {
  const _ContentPanels(this.constraints);

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: SizedBox(
          width: (constraints.maxWidth / 3).clamp(515, 560),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: const ConfigPanelMap(),
              ),
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
                  child: const CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(top: 16),
                        sliver: StoresList(useCompactLayout: false),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
