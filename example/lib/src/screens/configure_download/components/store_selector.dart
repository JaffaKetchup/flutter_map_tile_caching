import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../state/configure_download_provider.dart';

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
            child: Selector<ConfigureDownloadProvider, FMTCStore?>(
              selector: (context, provider) => provider.selectedStore,
              builder: (context, selectedStore, _) =>
                  FutureBuilder<Iterable<FMTCStore>>(
                future: FMTCRoot.stats.storesAvailable,
                builder: (context, snapshot) {
                  final items = snapshot.data
                      ?.map(
                        (e) => DropdownMenuItem<FMTCStore>(
                          value: e,
                          child: Text(e.storeName),
                        ),
                      )
                      .toList();
                  final text = snapshot.data == null
                      ? 'Loading...'
                      : snapshot.data!.isEmpty
                          ? 'None Available'
                          : 'None Selected';

                  return DropdownButton<FMTCStore>(
                    items: items,
                    onChanged: (store) => context
                        .read<ConfigureDownloadProvider>()
                        .selectedStore = store,
                    value: selectedStore,
                    hint: Text(text),
                    padding: const EdgeInsets.only(left: 12),
                  );
                },
              ),
            ),
          ),
        ],
      );
}
