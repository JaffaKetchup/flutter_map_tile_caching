part of 'browse_store_strategy_selector.dart';

class _BrowseStoreStrategySelectorDropdown extends StatelessWidget {
  const _BrowseStoreStrategySelectorDropdown({
    required this.storeName,
    required this.currentStrategy,
    required this.enabled,
    required this.isUnspecifiedSelector,
    required this.isExplicitlyExcluded,
  });

  final String storeName;
  final BrowseStoreStrategy? currentStrategy;
  final bool enabled;
  final bool isUnspecifiedSelector;
  final bool isExplicitlyExcluded;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButton<BrowseStoreStrategy?>(
          items: [null, ...BrowseStoreStrategy.values].map(
            (e) {
              final iconColor = isUnspecifiedSelector
                  ? BrowseStoreStrategySelector._unspecifiedSelectorColor
                  : null;

              final child = switch (e) {
                null when !enabled => const Icon(
                    Icons.disabled_by_default_rounded,
                  ),
                null when isUnspecifiedSelector => const Icon(
                    Icons.disabled_by_default_rounded,
                    color:
                        BrowseStoreStrategySelector._unspecifiedSelectorColor,
                  ),
                null => switch (context
                      .select<GeneralProvider, InternalBrowseStoreStrategy?>(
                    (provider) => provider.currentStores['(unspecified)'],
                  )) {
                    InternalBrowseStoreStrategy.read => Icon(
                        Icons.visibility,
                        color: isExplicitlyExcluded
                            ? BrowseStoreStrategySelector
                                ._unspecifiedSelectorExcludedColor
                            : BrowseStoreStrategySelector
                                ._unspecifiedSelectorColor,
                      ),
                    InternalBrowseStoreStrategy.readUpdate => Icon(
                        Icons.edit,
                        color: isExplicitlyExcluded
                            ? BrowseStoreStrategySelector
                                ._unspecifiedSelectorExcludedColor
                            : BrowseStoreStrategySelector
                                ._unspecifiedSelectorColor,
                      ),
                    InternalBrowseStoreStrategy.readUpdateCreate => Icon(
                        Icons.add,
                        color: isExplicitlyExcluded
                            ? BrowseStoreStrategySelector
                                ._unspecifiedSelectorExcludedColor
                            : BrowseStoreStrategySelector
                                ._unspecifiedSelectorColor,
                      ),
                    _ => Icon(
                        Icons.disabled_by_default_rounded,
                        color: isExplicitlyExcluded
                            ? BrowseStoreStrategySelector
                                ._unspecifiedSelectorExcludedColor
                            : BrowseStoreStrategySelector
                                ._unspecifiedSelectorColor,
                      ),
                  },
                BrowseStoreStrategy.read =>
                  Icon(Icons.visibility, color: iconColor),
                BrowseStoreStrategy.readUpdate =>
                  Icon(Icons.edit, color: iconColor),
                BrowseStoreStrategy.readUpdateCreate =>
                  Icon(Icons.add, color: iconColor),
              };

              return DropdownMenuItem(
                value: e,
                alignment: Alignment.center,
                child: child,
              );
            },
          ).toList(),
          value: currentStrategy,
          onChanged: enabled
              ? (v) {
                  final provider = context.read<GeneralProvider>();

                  if (v == null) {
                    provider.currentStores[storeName] =
                        InternalBrowseStoreStrategy.disable;
                  } else if (v == provider.inheritableBrowseStoreStrategy &&
                      !isUnspecifiedSelector) {
                    provider.currentStores[storeName] =
                        InternalBrowseStoreStrategy.inherit;
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
