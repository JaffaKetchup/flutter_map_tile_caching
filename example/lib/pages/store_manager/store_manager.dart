// ignore_for_file: prefer_void_to_null

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/list_tile_image.dart';
import 'components/store_modal.dart';

class StoreManager extends StatelessWidget {
  const StoreManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Manager'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/storeEditor'),
        label: const Text('Create New Store'),
        icon: const Icon(Icons.create_new_folder),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Consumer<GeneralProvider>(
          builder: (context, provider, _) {
            final MapCachingManager mcm = MapCachingManager(
                provider.parentDirectory!, provider.storeName);

            return StreamBuilder<void>(
              stream: mcm.watchCacheChanges(false)!,
              builder: (context, s) {
                return FutureBuilder<List<String>?>(
                  future: mcm.allStoresNamesAsync,
                  builder: (context, storeNames) {
                    if (!storeNames.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return ListView.separated(
                      itemBuilder: (context, i) {
                        final MapCachingManager currentMCM = MapCachingManager(
                            provider.parentDirectory!, storeNames.data![i]);

                        return ListTile(
                          title: Text(currentMCM.storeName),
                          subtitle: Text(
                              '${currentMCM.storeLength} tiles\n${(currentMCM.storeSize! / 1024).toStringAsFixed(2)} MiB'),
                          leading: buildListTileImage(currentMCM),
                          trailing: provider.storeName == currentMCM.storeName
                              ? const Icon(Icons.done)
                              : null,
                          onTap: () async {
                            provider.storeName = currentMCM.storeName;
                            provider.persistent!
                                .setString('lastUsedStore', provider.storeName);
                            PaintingBinding.instance?.imageCache?.clear();
                            provider.resetMap();
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return StoreModal(
                                  currentMCM: currentMCM,
                                  storeNames: storeNames.data!,
                                );
                              },
                            );
                          },
                        );
                      },
                      separatorBuilder: (context, _) => const Divider(),
                      itemCount: storeNames.data!.length,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
