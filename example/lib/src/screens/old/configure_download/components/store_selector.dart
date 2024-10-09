import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/download_configuration_provider.dart';

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
            child: Selector<DownloadConfigurationProvider, String?>(
              selector: (context, provider) => provider.selectedStoreName,
              builder: (context, selectedStore, _) =>
                  FutureBuilder<Iterable<FMTCStore>>(
                future: FMTCRoot.stats.storesAvailable,
                builder: (context, snapshot) {
                  final items = snapshot.data
                      ?.map(
                        (e) => DropdownMenuItem<String>(
                          value: e.storeName,
                          child: Text(e.storeName),
                        ),
                      )
                      .toList();
                  final text = snapshot.data == null
                      ? 'Loading...'
                      : snapshot.data!.isEmpty
                          ? 'None Available'
                          : 'None Selected';

                  return DropdownButton<String>(
                    items: items,
                    onChanged: (store) => context
                        .read<DownloadConfigurationProvider>()
                        .selectedStoreName = store,
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
