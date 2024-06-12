import 'package:flutter/material.dart';

import '../../map_config.dart';

class MapConfigSidePanel extends StatelessWidget {
  const MapConfigSidePanel({
    super.key,
    required this.selectedTab,
  });

  final int selectedTab;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: child,
        ),
        child: selectedTab == 0
            ? Container(
                margin: const EdgeInsets.only(
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                width: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: MapConfig(
                  leading: [
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Text(
                              'Stores & Config',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.help_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      );
}
