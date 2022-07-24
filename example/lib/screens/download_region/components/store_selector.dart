import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';
import '../../../shared/state/general_provider.dart';

class StoreSelector extends StatefulWidget {
  const StoreSelector({Key? key}) : super(key: key);

  @override
  State<StoreSelector> createState() => _StoreSelectorState();
}

class _StoreSelectorState extends State<StoreSelector> {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHOOSE A STORE'),
          Consumer2<DownloadProvider, GeneralProvider>(
            builder: (context, downloadProvider, generalProvider, _) =>
                FutureBuilder<List<StoreDirectory>>(
              future: FMTC.instance.rootDirectory.stats.storesAvailableAsync,
              builder: (context, snapshot) => DropdownButton<StoreDirectory>(
                items: snapshot.data
                    ?.map(
                      (e) => DropdownMenuItem<StoreDirectory>(
                        value: e,
                        child: Text(e.storeName),
                      ),
                    )
                    .toList(),
                onChanged: (store) => downloadProvider.setSelectedStore(store),
                value: downloadProvider.selectedStore ??
                    (generalProvider.currentStore == null
                        ? null
                        : FMTC.instance(generalProvider.currentStore!)),
                isExpanded: true,
                hint: Text(
                  snapshot.data == null
                      ? 'Loading...'
                      : snapshot.data!.isEmpty
                          ? 'None Available'
                          : 'None Selected',
                ),
              ),
            ),
          ),
        ],
      );
}
