import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../misc/components/loading_builder.dart';
import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/fab.dart';
import 'components/list_tile_image.dart';
import 'components/modals/store_modal.dart';

class StoreManager extends StatelessWidget {
  const StoreManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      floatingActionButton: const FAB(),
      body: Consumer<GeneralProvider>(
        builder: (context, provider, _) {
          return FutureBuilder<CacheDirectory>(
            future: MapCachingManager.normalCache,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return loadingScreen(
                    context, 'Waiting for the caching directory');
              }

              final List<String> availableStores =
                  MapCachingManager(snapshot.data!, provider.storeName)
                      .allStoresNames!;

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListView.separated(
                  itemCount: availableStores.length,
                  itemBuilder: (context, i) {
                    final MapCachingManager mcm =
                        MapCachingManager(snapshot.data!, availableStores[i]);

                    return ListTile(
                      title: Text(availableStores[i]),
                      subtitle: Text(
                          '${mcm.storeLength} tiles\n${(mcm.storeSize ?? 0).bytesToMegabytes.toStringAsPrecision(2)} MB'),
                      leading: buildListTileImage(mcm),
                      trailing: provider.storeName == availableStores[i]
                          ? const Icon(Icons.done)
                          : null,
                      onTap: () {
                        provider.currentMapCachingManager = mcm;
                        provider.storeName = availableStores[i];
                        provider.resetMap();
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return StoreModal(
                              mcm: mcm,
                              availableStores: availableStores,
                              provider: provider,
                            );
                          },
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, i) => const Divider(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
