part of 'browse_store_strategy_selector.dart';

class _BrowseStoreStrategySelectorCheckbox extends StatelessWidget {
  const _BrowseStoreStrategySelectorCheckbox({
    required this.strategyOption,
    required this.storeName,
    required this.currentStrategy,
    required this.enabled,
    required this.isUnspecifiedSelector,
  });

  final BrowseStoreStrategy strategyOption;
  final String storeName;
  final BrowseStoreStrategy? currentStrategy;
  final bool enabled;
  final bool isUnspecifiedSelector;

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
                        provider.inheritableBrowseStoreStrategy &&
                    !isUnspecifiedSelector) {
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
        activeColor: isUnspecifiedSelector
            ? BrowseStoreStrategySelector._unspecifiedSelectorColor
            : null,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.isEmpty) return Theme.of(context).colorScheme.surface;
          return null;
        }),
      );
}
