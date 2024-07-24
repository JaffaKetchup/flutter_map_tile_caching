import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/internal_store_read_write_behaviour.dart';
import '../../../../../../shared/state/general_provider.dart';

class ColumnHeadersAndInheritableSettings extends StatelessWidget {
  const ColumnHeadersAndInheritableSettings({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Inherit',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.settings_suggest),
                    ),
                  ),
                  VerticalDivider(width: 2),
                  Tooltip(
                    message: 'Read only',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.visibility),
                    ),
                  ),
                  Tooltip(
                    message: ' + update existing',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.edit),
                    ),
                  ),
                  Tooltip(
                    message: ' + create new',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Selector<GeneralProvider, StoreReadWriteBehaviour?>(
              selector: (context, provider) =>
                  provider.inheritableStoreReadWriteBehaviour,
              builder: (context, currentBehaviour, child) => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: StoreReadWriteBehavior.values.map(
                  (e) {
                    final value = currentBehaviour == e
                        ? true
                        : InternalStoreReadWriteBehaviour.priority
                                    .indexOf(currentBehaviour) <
                                InternalStoreReadWriteBehaviour.priority
                                    .indexOf(e)
                            ? false
                            : null;

                    return Checkbox.adaptive(
                      value: value,
                      onChanged: (v) => context
                              .read<GeneralProvider>()
                              .inheritableStoreReadWriteBehaviour =
                          v == null ? null : e,
                      tristate: true,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.comfortable,
                    );
                  },
                ).toList(growable: false),
              ),
            ),
          ),
          const Divider(
            height: 8,
            indent: 24,
            endIndent: 24,
          ),
        ],
      );
}
