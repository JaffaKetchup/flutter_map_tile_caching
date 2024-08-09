import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/internal_store_read_write_behaviour.dart';
import '../../../../../../shared/state/general_provider.dart';

class StoreReadWriteBehaviourSelector extends StatelessWidget {
  const StoreReadWriteBehaviourSelector({
    super.key,
    required this.storeName,
    required this.enabled,
  });

  final String storeName;
  final bool enabled;

  @override
  Widget build(BuildContext context) =>
      Selector<GeneralProvider, InternalBrowseStoreStrategy?>(
        selector: (context, provider) => provider.currentStores[storeName],
        builder: (context, currentBehaviour, child) =>
            Selector<GeneralProvider, BrowseStoreStrategy?>(
          selector: (context, provider) =>
              provider.inheritableBrowseStoreStrategy,
          builder: (context, inheritableBehaviour, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox.adaptive(
                value:
                    currentBehaviour == InternalBrowseStoreStrategy.inherit ||
                        currentBehaviour == null,
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
              ...BrowseStoreStrategy.values.map(
                (e) => _StoreReadWriteBehaviourSelectorCheckbox(
                  storeName: storeName,
                  representativeBehaviour: e,
                  currentBehaviour: currentBehaviour == null
                      ? inheritableBehaviour
                      : currentBehaviour
                          .toBrowseStoreStrategy(inheritableBehaviour),
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
      );
}

class _StoreReadWriteBehaviourSelectorCheckbox extends StatelessWidget {
  const _StoreReadWriteBehaviourSelectorCheckbox({
    required this.storeName,
    required this.representativeBehaviour,
    required this.currentBehaviour,
    required this.enabled,
  });

  final String storeName;
  final BrowseStoreStrategy representativeBehaviour;
  final BrowseStoreStrategy? currentBehaviour;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Checkbox.adaptive(
        value: currentBehaviour == representativeBehaviour
            ? true
            : InternalBrowseStoreStrategy.priority.indexOf(currentBehaviour) <
                    InternalBrowseStoreStrategy.priority
                        .indexOf(representativeBehaviour)
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
                } else if (representativeBehaviour ==
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
                    representativeBehaviour,
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
