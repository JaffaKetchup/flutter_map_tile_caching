import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';
import 'components/list.dart';

class ConfigPanelStoresSliver extends StatelessWidget {
  const ConfigPanelStoresSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Selector<GeneralProvider, bool?>(
                selector: (context, provider) => provider.storesSelectionMode,
                builder: (context, storesSelectionMode, _) => SegmentedButton(
                  segments: const [
                    ButtonSegment(
                      value: null,
                      icon: Icon(Icons.deselect_rounded),
                      label: Text('Disabled'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.select_all_rounded),
                      label: Text('Automatic'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.highlight_alt_rounded),
                      label: Text('Manual'),
                    ),
                  ],
                  selected: {storesSelectionMode},
                  onSelectionChanged: (value) => context
                      .read<GeneralProvider>()
                      .storesSelectionMode = value.single,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          const StoresList(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
}
