// ignore_for_file: prefer_void_to_null

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/list_tile_image.dart';
import 'components/store_modal.dart';

class StoreManager extends StatefulWidget {
  const StoreManager({Key? key}) : super(key: key);

  @override
  State<StoreManager> createState() => _StoreManagerState();
}

class _StoreManagerState extends State<StoreManager> {
  late MapCachingManager mcm;
  late final Stream<void> stream;
  late Future<List<String>> future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm = MapCachingManager(context.read<GeneralProvider>().parentDirectory!);
    stream = mcm.watchCacheChanges(
      false,
      fileSystemEvents: FileSystemEvent.all,
    );
    future = mcm.allStoresNamesAsync;

    stream.listen((_) => future = mcm.allStoresNamesAsync);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/storeEditor'),
        label: const Text('Create New Store'),
        icon: const Icon(Icons.create_new_folder),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          width: double.infinity,
          child: Consumer<GeneralProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<void>(
                stream: stream,
                builder: (context, s) {
                  return FutureBuilder<List<String>>(
                    future: future,
                    builder: (context, storeNames) {
                      if (storeNames.connectionState != ConnectionState.done ||
                          !storeNames.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return DescribedFeatureOverlay(
                        featureId: 'storeSelector',
                        tapTarget: const Icon(Icons.edit),
                        title: const Text('Store Selector'),
                        description: const Text(
                          'Tap on a store listing to choose it as the current store, and it will be persisted between app restarts in shared preferences (not built into API).\nOr, long press to open a menu with more actions. Try it now...',
                        ),
                        contentLocation: ContentLocation.above,
                        overflowMode: OverflowMode.extendBackground,
                        onComplete: () async {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return StoreModal(
                                currentMCM: mcm.copyWith(
                                    storeName: storeNames.data![0]),
                                storeNames: storeNames.data!,
                              );
                            },
                          );
                          return true;
                        },
                        child: ListView.separated(
                          itemBuilder: (context, i) {
                            final MapCachingManager currentMCM =
                                mcm.copyWith(storeName: storeNames.data![i]);

                            return StreamBuilder<void>(
                                stream: currentMCM.watchStoreChanges(true),
                                builder: (context, _) {
                                  return ListTile(
                                    title: Text(currentMCM.storeName!),
                                    subtitle: FutureBuilder<List<num>>(
                                      future: Future.wait([
                                        currentMCM.storeLengthAsync,
                                        currentMCM.storeSizeAsync,
                                      ]),
                                      builder: (context, stats) {
                                        if (stats.connectionState !=
                                                ConnectionState.done ||
                                            !stats.hasData) {
                                          return const Text(
                                              'Loading Statistics...\nPlease Wait...');
                                        }

                                        return Text(
                                            '${stats.data![0]} tiles\n${(stats.data![1] / 1024).toStringAsFixed(2)} MiB');
                                      },
                                    ),
                                    leading: buildListTileImage(currentMCM),
                                    trailing: provider.storeName ==
                                            currentMCM.storeName
                                        ? const Icon(Icons.done)
                                        : null,
                                    onTap: () async {
                                      provider.storeName =
                                          currentMCM.storeName!;
                                      provider.persistent!.setString(
                                          'lastUsedStore', provider.storeName);
                                      PaintingBinding.instance?.imageCache
                                          ?.clear();
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
                                });
                          },
                          separatorBuilder: (context, _) => const Divider(),
                          itemCount: storeNames.data!.length,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
