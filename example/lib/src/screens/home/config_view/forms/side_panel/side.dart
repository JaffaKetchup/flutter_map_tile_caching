import 'package:flutter/material.dart';

import '../../panels/behaviour/behaviour.dart';
import '../../panels/map/map.dart';
import '../../panels/stores/stores.dart';

class ConfigViewSide extends StatelessWidget {
  const ConfigViewSide({
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
          axis: Axis.horizontal,
          axisAlignment: 1, // Align right
          sizeFactor: animation,
          child: child,
        ),
        child:
            selectedTab == 0 ? const _ContentPanels() : const SizedBox.shrink(),
      );
}

class _ContentPanels extends StatelessWidget {
  const _ContentPanels();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: SizedBox(
          width: 450,
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Stores & Config',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.help_outline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: const ConfigPanelBehaviour(),
              ),
              const SizedBox(height: 16),
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints.expand(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: const ConfigPanelStoresSliver(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
