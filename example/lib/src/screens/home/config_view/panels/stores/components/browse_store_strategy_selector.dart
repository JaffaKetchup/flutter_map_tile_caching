import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/internal_store_read_write_behaviour.dart';
import '../../../../../../shared/state/general_provider.dart';

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

  @override
  Widget build(BuildContext context) =>
      Selector<GeneralProvider, InternalBrowseStoreStrategy?>(
        selector: (context, provider) => provider.currentStores[storeName],
        builder: (context, currentStrategy, child) {
          final inheritableStrategy = inheritable
              ? context.select<GeneralProvider, BrowseStoreStrategy?>(
                  (provider) => provider.inheritableBrowseStoreStrategy,
                )
              : null;
          final resolvedCurrentStrategy = currentStrategy == null
              ? inheritableStrategy
              : currentStrategy.toBrowseStoreStrategy(inheritableStrategy);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inheritable) ...[
                Checkbox.adaptive(
                  value:
                      currentStrategy == InternalBrowseStoreStrategy.inherit ||
                          currentStrategy == null,
                  onChanged: enabled
                      ? (v) {
                          final provider = context.read<GeneralProvider>();

                          provider
                            ..currentStores[storeName] = v!
                                ? InternalBrowseStoreStrategy.inherit
                                : InternalBrowseStoreStrategy
                                    .fromBrowseStoreStrategy(
                                    provider.inheritableBrowseStoreStrategy,
                                  )
                            ..changedCurrentStores();
                        }
                      : null,
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
                )
              else
                ...BrowseStoreStrategy.values.map(
                  (e) => _BrowseStoreStrategySelectorCheckbox(
                    storeName: storeName,
                    strategyOption: e,
                    currentStrategy: resolvedCurrentStrategy,
                    enabled: enabled,
                  ),
                ),
            ],
          );
        },
      );
}

class _BrowseStoreStrategySelectorDropdown extends StatelessWidget {
  const _BrowseStoreStrategySelectorDropdown({
    required this.storeName,
    required this.currentStrategy,
    required this.enabled,
  });

  final String storeName;
  final BrowseStoreStrategy? currentStrategy;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButton(
          items: <BrowseStoreStrategy?>[null]
              .followedBy(BrowseStoreStrategy.values)
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  alignment: Alignment.center,
                  child: switch (e) {
                    null => const Icon(Icons.disabled_by_default_rounded),
                    BrowseStoreStrategy.read => const Icon(Icons.visibility),
                    BrowseStoreStrategy.readUpdate => const Icon(Icons.edit),
                    BrowseStoreStrategy.readUpdateCreate =>
                      const Icon(Icons.add),
                  },
                ),
              )
              .toList(),
          value: currentStrategy,
          onChanged: enabled
              ? (BrowseStoreStrategy? v) {
                  final provider = context.read<GeneralProvider>();

                  if (v == provider.inheritableBrowseStoreStrategy) {
                    provider.currentStores[storeName] =
                        InternalBrowseStoreStrategy.inherit;
                  } else if (v == null) {
                    provider.currentStores[storeName] =
                        InternalBrowseStoreStrategy.disable;
                  } else {
                    provider.currentStores[storeName] =
                        InternalBrowseStoreStrategy.fromBrowseStoreStrategy(
                      v,
                    );
                  }

                  provider.changedCurrentStores();
                }
              : null,
        ),
      );
}

class _BrowseStoreStrategySelectorCheckbox extends StatelessWidget {
  const _BrowseStoreStrategySelectorCheckbox({
    required this.storeName,
    required this.strategyOption,
    required this.currentStrategy,
    required this.enabled,
  });

  final String storeName;
  final BrowseStoreStrategy strategyOption;
  final BrowseStoreStrategy? currentStrategy;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Checkbox.adaptive(
        value: currentStrategy == strategyOption
            ? true
            : InternalBrowseStoreStrategy.priority.indexOf(currentStrategy) <
                    InternalBrowseStoreStrategy.priority.indexOf(strategyOption)
                ? false
                : null,
        onChanged: enabled
            ? (v) {
                final provider = context.read<GeneralProvider>();

                if (v == null) {
                  // Deselected current selection
                  //  > Disable inheritance and disable store
                  provider.currentStores[storeName] =
                      InternalBrowseStoreStrategy.disable;
                } else if (strategyOption ==
                    provider.inheritableBrowseStoreStrategy) {
                  // Selected same as inherited
                  //  > Automatically enable inheritance (assumed desire, can be undone)
                  provider.currentStores[storeName] =
                      InternalBrowseStoreStrategy.inherit;
                } else {
                  // Selected something else
                  //  > Disable inheritance and change store
                  provider.currentStores[storeName] =
                      InternalBrowseStoreStrategy.fromBrowseStoreStrategy(
                    strategyOption,
                  );
                }
                provider.changedCurrentStores();
              }
            : null,
        tristate: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.comfortable,
      );
}
