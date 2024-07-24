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
      Selector<GeneralProvider, InternalStoreReadWriteBehaviour?>(
        selector: (context, provider) => provider.currentStores[storeName],
        builder: (context, currentBehaviour, child) =>
            Selector<GeneralProvider, StoreReadWriteBehaviour?>(
          selector: (context, provider) =>
              provider.inheritableStoreReadWriteBehaviour,
          builder: (context, inheritableBehaviour, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox.adaptive(
                value: currentBehaviour ==
                        InternalStoreReadWriteBehaviour.inherit ||
                    currentBehaviour == null,
                onChanged: enabled
                    ? (v) {
                        final provider = context.read<GeneralProvider>();

                        provider
                          ..currentStores[storeName] = v!
                              ? InternalStoreReadWriteBehaviour.inherit
                              : InternalStoreReadWriteBehaviour
                                  .fromStoreReadWriteBehavior(
                                  provider.inheritableStoreReadWriteBehaviour,
                                )
                          ..changedCurrentStores();
                      }
                    : null,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.comfortable,
              ),
              const VerticalDivider(width: 2),
              ...StoreReadWriteBehavior.values.map(
                (e) => _StoreReadWriteBehaviourSelectorCheckbox(
                  storeName: storeName,
                  representativeBehaviour: e,
                  currentBehaviour: currentBehaviour == null
                      ? inheritableBehaviour
                      : currentBehaviour
                          .toStoreReadWriteBehavior(inheritableBehaviour),
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
  final StoreReadWriteBehaviour representativeBehaviour;
  final StoreReadWriteBehaviour? currentBehaviour;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Checkbox.adaptive(
        value: currentBehaviour == representativeBehaviour
            ? true
            : InternalStoreReadWriteBehaviour.priority
                        .indexOf(currentBehaviour) <
                    InternalStoreReadWriteBehaviour.priority
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
                      InternalStoreReadWriteBehaviour.disable;
                } else if (representativeBehaviour ==
                    provider.inheritableStoreReadWriteBehaviour) {
                  // Selected same as inherited
                  //  > Automatically enable inheritance (assumed desire, can be undone)
                  provider.currentStores[storeName] =
                      InternalStoreReadWriteBehaviour.inherit;
                } else {
                  // Selected something else
                  //  > Disable inheritance and change store
                  provider.currentStores[storeName] =
                      InternalStoreReadWriteBehaviour
                          .fromStoreReadWriteBehavior(
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
