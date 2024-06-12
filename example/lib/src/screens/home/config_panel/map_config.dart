import 'package:flutter/material.dart' hide BottomSheet;
import 'package:provider/provider.dart';

import '../../../shared/state/general_provider.dart';
import 'components/stores_list.dart';

class MapConfig extends StatefulWidget {
  const MapConfig({
    super.key,
    this.controller,
    this.leading = const [],
  });

  final ScrollController? controller;
  final List<Widget> leading;

  @override
  State<MapConfig> createState() => _MapConfigState();
}

class _MapConfigState extends State<MapConfig> {
  final urlTextController = TextEditingController(
    text: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller: widget.controller,
        slivers: [
          ...widget.leading,
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Configuration',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Selector<GeneralProvider, bool?>(
                selector: (context, provider) => provider.storesSelectionMode,
                builder: (context, storesSelectionMode, _) => SegmentedButton(
                  segments: const [
                    ButtonSegment(
                      value: null,
                      icon: Icon(Icons.deselect),
                      label: Text('Disabled'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.select_all),
                      label: Text('Use All'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.highlight_alt),
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
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth,
                  child: DropdownMenu<String>(
                    controller: urlTextController,
                    width: constraints.maxWidth,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    leadingIcon: const Icon(Icons.link),
                    label: const Text('URL Template'),
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: true,
                      //contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                    ),
                    /*onSelected: (String? urlTemplate) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },*/
                    dropdownMenuEntries: [
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      'b',
                      'ab',
                    ]
                        .map(
                          (urlTemplate) => DropdownMenuEntry(
                            value: urlTemplate,
                            label: urlTemplate,
                            labelWidget: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(urlTemplate),
                                const Text(
                                  'Used by: x',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Stores',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const StoresList(),
        ],
      );
}
