import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/general_provider.dart';
import '../../main/pages/region_selection/state/region_selection_provider.dart';

class StoreSelector extends StatefulWidget {
  const StoreSelector({super.key});

  @override
  State<StoreSelector> createState() => _StoreSelectorState();
}

class _StoreSelectorState extends State<StoreSelector> {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Text('Store'),
          const Spacer(),
          IntrinsicWidth(
            child: Consumer2<RegionSelectionProvider, GeneralProvider>(
              builder: (context, downloadProvider, generalProvider, _) =>
                  FutureBuilder<Iterable<FMTCStore>>(
                future: FMTCRoot.stats.storesAvailable,
                builder: (context, snapshot) => DropdownButton<FMTCStore>(
                  items: snapshot.data
                      ?.map(
                        (e) => DropdownMenuItem<FMTCStore>(
                          value: e,
                          child: Text(e.storeName),
                        ),
                      )
                      .toList(),
                  onChanged: (store) =>
                      downloadProvider.setSelectedStore(store),
                  value: downloadProvider.selectedStore ??
                      (generalProvider.currentStore == null
                          ? null
                          : FMTCStore(generalProvider.currentStore!)),
                  hint: Text(
                    snapshot.data == null
                        ? 'Loading...'
                        : snapshot.data!.isEmpty
                            ? 'None Available'
                            : 'None Selected',
                  ),
                  padding: const EdgeInsets.only(left: 12),
                ),
              ),
            ),
          ),
        ],
      );
}
