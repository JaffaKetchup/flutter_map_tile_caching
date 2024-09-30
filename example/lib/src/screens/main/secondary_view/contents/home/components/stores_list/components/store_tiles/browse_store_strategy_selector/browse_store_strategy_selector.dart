import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../../shared/misc/internal_store_read_write_behaviour.dart';
import '../../../../../../../../../../shared/state/general_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentStrategy =
        context.select<GeneralProvider, InternalBrowseStoreStrategy?>(
      (provider) => provider.currentStores[storeName],
    );
    final unspecifiedStrategy =
        context.select<GeneralProvider, InternalBrowseStoreStrategy?>(
      (provider) => provider.currentStores['(unspecified)'],
    );
    final inheritableStrategy = inheritable
        ? context.select<GeneralProvider, BrowseStoreStrategy?>(
            (provider) => provider.inheritableBrowseStoreStrategy,
          )
        : null;

    final resolvedCurrentStrategy = currentStrategy == null
        ? inheritableStrategy
        : currentStrategy.toBrowseStoreStrategy(inheritableStrategy);
    final isUsingUnselectedStrategy = resolvedCurrentStrategy == null &&
        unspecifiedStrategy != InternalBrowseStoreStrategy.disable &&
        enabled;

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inheritable) ...[
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
          )
        else
          Stack(
            children: [
              Transform.translate(
                offset: const Offset(2, 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: BrowseStoreStrategySelector._unspecifiedSelectorColor
                        .withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  width: isUsingUnselectedStrategy
                      ? switch (unspecifiedStrategy) {
                          InternalBrowseStoreStrategy.read => 40,
                          InternalBrowseStoreStrategy.readUpdate => 85,
                          InternalBrowseStoreStrategy.readUpdateCreate => 128,
                          _ => 0,
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
