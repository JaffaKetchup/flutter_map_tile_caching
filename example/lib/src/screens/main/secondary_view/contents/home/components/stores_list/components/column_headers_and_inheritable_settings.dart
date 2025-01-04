import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../shared/misc/internal_store_read_write_behaviour.dart';
import '../../../../../../../../shared/state/general_provider.dart';

class ColumnHeadersAndInheritableSettings extends StatelessWidget {
  const ColumnHeadersAndInheritableSettings({
    super.key,
    required this.useCompactLayout,
  });

  final bool useCompactLayout;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28) +
                (useCompactLayout
                    ? const EdgeInsets.only(right: 32)
                    : EdgeInsets.zero),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Tooltip(
                    message: 'Inherit',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.settings_suggest),
                    ),
                  ),
                  const VerticalDivider(width: 2),
                  if (useCompactLayout)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.settings),
                    )
                  else ...[
                    const Tooltip(
                      message: 'Read only',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.visibility),
                      ),
                    ),
                    const Tooltip(
                      message: ' + update existing',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.edit),
                      ),
                    ),
                    const Tooltip(
                      message: ' + create new',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 20),
              Tooltip(
                message: 'These inheritance options are tracked manually by\n'
                    'the app and not FMTC. This enables both inheritance\n'
                    'and "All unspecified" (which uses `otherStoresStrategy`\n'
                    'in FMTC) to be represented in the example app. Tap\n'
                    'the debug icon in the map attribution to see how the\n'
                    'store configuration is resolved and passed to FMTC.',
                textAlign: TextAlign.center,
                child: Icon(
                  Icons.help_outline,
                  color: Colors.black.withAlpha(255 ~/ 3),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Selector<GeneralProvider, BrowseStoreStrategy?>(
                  selector: (context, provider) =>
                      provider.inheritableBrowseStoreStrategy,
                  builder: (context, currentBehaviour, child) {
                    if (useCompactLayout) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DropdownButton(
                            items: <BrowseStoreStrategy?>[null]
                                .followedBy(BrowseStoreStrategy.values)
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    alignment: Alignment.center,
                                    child: switch (e) {
                                      null => const Icon(
                                          Icons.disabled_by_default_rounded,
                                        ),
                                      BrowseStoreStrategy.read =>
                                        const Icon(Icons.visibility),
                                      BrowseStoreStrategy.readUpdate =>
                                        const Icon(Icons.edit),
                                      BrowseStoreStrategy.readUpdateCreate =>
                                        const Icon(Icons.add),
                                    },
                                  ),
                                )
                                .toList(),
                            value: currentBehaviour,
                            onChanged: (v) => context
                                .read<GeneralProvider>()
                                .inheritableBrowseStoreStrategy = v,
                          ),
                        ),
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: BrowseStoreStrategy.values.map(
                        (e) {
                          final value = currentBehaviour == e
                              ? true
                              : InternalBrowseStoreStrategy.priority
                                          .indexOf(currentBehaviour) <
                                      InternalBrowseStoreStrategy.priority
                                          .indexOf(e)
                                  ? false
                                  : null;

                          return Checkbox.adaptive(
                            value: value,
                            onChanged: (v) => context
                                    .read<GeneralProvider>()
                                    .inheritableBrowseStoreStrategy =
                                v == null ? null : e,
                            tristate: true,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            visualDensity: VisualDensity.comfortable,
                          );
                        },
                      ).toList(growable: false),
                    );
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 8, indent: 12, endIndent: 12),
        ],
      );
}
