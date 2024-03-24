import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../export_import/export_import.dart';
import '../../../store_editor/store_editor.dart';
import 'components/empty_indicator.dart';
import 'components/header.dart';
import 'components/root_stats_pane.dart';
import 'components/store_tile.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  late final storesStream = FMTCRoot.stats
      .watchStores(triggerImmediately: true)
      .asyncMap((_) => FMTCRoot.stats.storesAvailable);

  @override
  Widget build(BuildContext context) {
    const loadingIndicator = LoadingIndicator('Retrieving Stores');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Header(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: storesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: loadingIndicator,
                      );
                    }

                    if (snapshot.data!.isEmpty) {
                      return const Column(
                        children: [
                          RootStatsPane(),
                          Expanded(child: EmptyIndicator()),
                        ],
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const RootStatsPane();
                        }

                        // Ensure the store buttons are not obscured by the FABs
                        if (index >= snapshot.data!.length + 1) {
                          return const SizedBox(height: 124);
                        }

                        final storeName =
                            snapshot.data!.elementAt(index - 1).storeName;
                        return FutureBuilder(
                          future: FMTCStore(storeName).manage.ready,
                          builder: (context, snapshot) {
                            if (snapshot.data == null) {
                              return const SizedBox.shrink();
                            }

                            return StoreTile(storeName: storeName);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'importExport',
            tooltip: 'Export/Import',
            shape: const CircleBorder(),
            child: const Icon(Icons.folder_zip_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<String>(
                builder: (BuildContext context) => const ExportImportPopup(),
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
}
