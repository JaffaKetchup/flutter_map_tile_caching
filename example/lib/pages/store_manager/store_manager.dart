// ignore_for_file: prefer_void_to_null

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
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
              stream: mcm.watchCacheChanges!,
              builder: (context, _) {
                final List<String> storeNames = mcm.allStoresNames!;

                return ListView.separated(
                  itemBuilder: (context, i) {
                    final MapCachingManager currentMCM = MapCachingManager(
                        provider.parentDirectory!, storeNames[i]);

                    return ListTile(
                      title: Text(currentMCM.storeName),
                      subtitle: Text(
                          '${currentMCM.storeLength} tiles\n${currentMCM.storeSize!.toStringAsFixed(2)} KiB'),
                      leading: buildListTileImage(currentMCM),
                      trailing: provider.storeName == currentMCM.storeName
                          ? const Icon(Icons.done)
                          : null,
                      onTap: () async {
                        provider.storeName = currentMCM.storeName;
                        provider.persistent!
                            .setString('lastUsedStore', provider.storeName);
                        //PaintingBinding.instance?.imageCache?.clearLiveImages();
                        //PaintingBinding.instance?.imageCache?.clear();
                        //print(PaintingBinding
                        //    .instance?.imageCache?.maximumSize = 0);
                        provider.resetMap();
                        Phoenix.rebirth(context);
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return StoreModal(
                              currentMCM: currentMCM,
                              storeNames: storeNames,
                            );
                          },
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, _) => const Divider(),
                  itemCount: storeNames.length,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
