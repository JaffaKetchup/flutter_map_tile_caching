import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/misc/exts/size_formatter.dart';
import '../../../import_store/import_store.dart';
import '../../../store_editor/store_editor.dart';
import 'components/empty_indicator.dart';
import 'components/header.dart';
import 'components/stat_display.dart';
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
  Widget build(BuildContext context) {
    const loadingIndicator = LoadingIndicator('Retrieving Stores');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: StreamBuilder(
            stream: watchStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return loadingIndicator;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Header(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder(
                      future: FMTCRoot.stats.storesAvailable,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: loadingIndicator,
                          );
                        }

                        if (snapshot.data!.isEmpty) {
                          return const EmptyIndicator();
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length + 2,
                          itemBuilder: (context, index) {
                            final addRootStats = index == 0;

                            if (addRootStats) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceEvenly,
                                  runAlignment: WrapAlignment.spaceEvenly,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 20,
                                  children: [
                                    FutureBuilder(
                                      future: FMTCRoot.stats.length,
                                      builder: (context, snapshot) =>
                                          StatDisplay(
                                        statistic: snapshot.data?.toString(),
                                        description: 'total tiles',
                                      ),
                                    ),
                                    FutureBuilder(
                                      future: FMTCRoot.stats.size,
                                      builder: (context, snapshot) =>
                                          StatDisplay(
                                        statistic: snapshot.data == null
                                            ? null
                                            : ((snapshot.data! * 1024)
                                                .asReadableSize),
                                        description: 'total tiles size',
                                      ),
                                    ),
                                    FutureBuilder(
                                      future: FMTCRoot.stats.realSize,
                                      builder: (context, snapshot) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          StatDisplay(
                                            statistic: snapshot.data == null
                                                ? null
                                                : ((snapshot.data! * 1024)
                                                    .asReadableSize),
                                            description: 'database size',
                                          ),
                                          const SizedBox.square(dimension: 6),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.help_outline),
                                            onPressed: () =>
                                                showDatabaseSizeInfoDialog(
                                              context,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final addSpace = index >= snapshot.data!.length + 1;
                            if (addSpace) return const SizedBox(height: 124);

                            return StoreTile(
                              storeName:
                                  snapshot.data!.elementAt(index - 1).storeName,
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
            shape: const CircleBorder(),
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

  void showDatabaseSizeInfoDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Database Size'),
        content: const Text(
          '''
This measurement refers to the actual size of the database root (which may be a
flat/file or another structure). Includes database overheads, and may not follow
the total tiles size in a linear relationship, or any relationship at all.''',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
