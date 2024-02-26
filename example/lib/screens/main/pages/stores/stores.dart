import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../import_store/import_store.dart';
import '../../../store_editor/store_editor.dart';
import 'components/empty_indicator.dart';
import 'components/header.dart';
import 'components/store_tile.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  late final watchStream = FMTCRoot.stats.watchStores(
    triggerImmediately: true,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder(
              stream: watchStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingIndicator('Retrieving Stores');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Header(),
                    const Divider(),
                    const Placeholder(fallbackHeight: 100),
                    const Divider(),
                    Expanded(
                      child: FutureBuilder(
                        future: FMTCRoot.stats.storesAvailable,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: LoadingIndicator('Retrieving Stores'),
                            );
                          }

                          if (snapshot.data!.isEmpty) {
                            return const EmptyIndicator();
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.length + 1,
                            itemBuilder: (context, index) {
                              final addSpace = index >= snapshot.data!.length;
                              if (addSpace) return const SizedBox(height: 124);

                              return StoreTile(
                                storeName:
                                    snapshot.data!.elementAt(index).storeName,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Import Store',
              child: const Icon(Icons.file_open_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<String>(
                  builder: (BuildContext context) => const ImportStorePopup(),
                  fullscreenDialog: true,
                ),
              ),
            ),
            const SizedBox.square(dimension: 12),
            FloatingActionButton.extended(
              label: const Text('Create Store'),
              icon: const Icon(Icons.create_new_folder_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<String>(
                  builder: (BuildContext context) => const StoreEditorPopup(
                    existingStoreName: null,
                    isStoreInUse: false,
                  ),
                  fullscreenDialog: true,
                ),
              ),
            ),
          ],
        ),
      );
}
