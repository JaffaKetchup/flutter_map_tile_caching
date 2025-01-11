import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../../../../shared/misc/internal_store_read_write_behaviour.dart';
import '../../../../../../../../../../../../shared/state/general_provider.dart';

part 'checkbox.dart';
part 'dropdown.dart';

class BrowseStoreStrategySelector extends StatelessWidget {
  const BrowseStoreStrategySelector({
    super.key,
    required this.storeName,
    required this.enabled,
    this.inheritable = true,
    required this.useCompactLayout,
  });

  final String storeName;
  final bool enabled;
  final bool inheritable;
  final bool useCompactLayout;

  static const _unspecifiedSelectorColor = Colors.pinkAccent;
  static const _unspecifiedSelectorExcludedColor = Colors.purple;

  @override
  Widget build(BuildContext context) {
    final currentStrategy =
        context.select<GeneralProvider, InternalBrowseStoreStrategy?>(
      (provider) => provider.currentStores[storeName],
    );
    final unspecifiedStrategy = context
        .select<GeneralProvider, InternalBrowseStoreStrategy?>(
          (provider) => provider.currentStores['(unspecified)'],
        )
        ?.toBrowseStoreStrategy();
    final inheritableStrategy = inheritable
        ? context.select<GeneralProvider, BrowseStoreStrategy?>(
            (provider) => provider.inheritableBrowseStoreStrategy,
          )
        : null;

    final resolvedCurrentStrategy = currentStrategy == null
        ? inheritableStrategy
        : currentStrategy.toBrowseStoreStrategy(inheritableStrategy);
    final isUsingUnselectedStrategy = resolvedCurrentStrategy == null &&
        unspecifiedStrategy != null &&
        enabled;

    final showExplicitExcludeCheckbox =
        resolvedCurrentStrategy == null && isUsingUnselectedStrategy;

    final isExplicitlyExcluded = showExplicitExcludeCheckbox &&
        context.select<GeneralProvider, bool>(
          (provider) => provider.explicitlyExcludedStores.contains(storeName),
        );

    // Parameter meaning obvious from context, also callback
    // ignore: avoid_positional_boolean_parameters
    void changedInheritCheckbox(bool? value) {
      final provider = context.read<GeneralProvider>();

      provider
        ..currentStores[storeName] = value!
            ? InternalBrowseStoreStrategy.inherit
            : InternalBrowseStoreStrategy.fromBrowseStoreStrategy(
                provider.inheritableBrowseStoreStrategy,
              )
        ..changedCurrentStores();
    }

    // Parameter meaning obvious from context, also callback
    // ignore: avoid_positional_boolean_parameters
    void changedExplicitlyExcludeCheckbox(bool? value) {
      final provider = context.read<GeneralProvider>();

      if (value!) {
        provider.explicitlyExcludedStores.add(storeName);
      } else {
        provider.explicitlyExcludedStores.remove(storeName);
      }

      provider.changedExplicitlyExcludedStores();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inheritable) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(99),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: Tween<double>(begin: 0, end: 1).animate(animation),
                axis: Axis.horizontal,
                axisAlignment: 1,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: showExplicitExcludeCheckbox
                  ? Tooltip(
                      message: 'Explicitly disable',
                      child: Padding(
                        padding: const EdgeInsets.all(4) +
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          spacing: 6,
                          children: [
                            const Icon(Icons.disabled_by_default_rounded),
                            Checkbox.adaptive(
                              value: isExplicitlyExcluded,
                              onChanged: changedExplicitlyExcludeCheckbox,
                              activeColor: BrowseStoreStrategySelector
                                  ._unspecifiedSelectorExcludedColor,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Checkbox.adaptive(
            value: currentStrategy == InternalBrowseStoreStrategy.inherit ||
                currentStrategy == null,
            onChanged: enabled ? changedInheritCheckbox : null,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.comfortable,
          ),
          const VerticalDivider(width: 2),
        ],
        if (useCompactLayout)
          _BrowseStoreStrategySelectorDropdown(
            storeName: storeName,
            currentStrategy: resolvedCurrentStrategy,
            enabled: enabled,
            isUnspecifiedSelector: storeName == '(unspecified)',
            isExplicitlyExcluded: isExplicitlyExcluded,
          )
        else
          Stack(
            children: [
              Transform.translate(
                offset: const Offset(2, 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isExplicitlyExcluded
                        ? BrowseStoreStrategySelector
                            ._unspecifiedSelectorExcludedColor
                            .withAlpha(255 ~/ 2)
                        : BrowseStoreStrategySelector._unspecifiedSelectorColor
                            .withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  width: isUsingUnselectedStrategy
                      ? switch (unspecifiedStrategy) {
                          BrowseStoreStrategy.read => 40,
                          BrowseStoreStrategy.readUpdate => 85,
                          BrowseStoreStrategy.readUpdateCreate => 128,
                        }
                      : 0,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...BrowseStoreStrategy.values.map(
                    (e) => _BrowseStoreStrategySelectorCheckbox(
                      strategyOption: e,
                      storeName: storeName,
                      currentStrategy: resolvedCurrentStrategy,
                      enabled: enabled,
                      isUnspecifiedSelector: storeName == '(unspecified)',
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
