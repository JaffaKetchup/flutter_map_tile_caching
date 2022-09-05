import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../import_store/import_store.dart';
import '../../../store_editor/store_editor.dart';
import 'components/empty_indicator.dart';
import 'components/header.dart';
import 'components/store_tile.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({Key? key}) : super(key: key);

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  late Future<List<StoreDirectory>> _stores;

  @override
  void initState() {
    super.initState();

    void listStores() =>
        _stores = FMTC.instance.rootDirectory.stats.storesAvailableAsync;

    listStores();
    FMTC.instance.rootDirectory.stats.watchChanges(
      rootParts: [RootParts.stores],
    ).listen((_) {
      if (mounted) {
        listStores();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<StoreDirectory>>(
                    future: _stores,
                    builder: (context, snapshot) => snapshot.hasData
                        ? snapshot.data!.isEmpty
                            ? const EmptyIndicator()
                            : ListView.builder(
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) => StoreTile(
                                  context: context,
                                  storeName: snapshot.data![index].storeName,
                                  key:
                                      ValueKey(snapshot.data![index].storeName),
                                ),
                              )
                        : const LoadingIndicator(
                            message: 'Loading Stores...',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.create_new_folder,
          activeIcon: Icons.close,
          children: [
            SpeedDialChild(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<String>(
                  builder: (BuildContext context) => const StoreEditorPopup(
                    existingStoreName: null,
                    isStoreInUse: false,
                  ),
                  fullscreenDialog: true,
                ),
              ),
              child: const Icon(Icons.add),
              label: 'Create New Store',
            ),
            SpeedDialChild(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<String>(
                  builder: (BuildContext context) => const ImportStorePopup(),
                  fullscreenDialog: true,
                ),
              ),
              child: const Icon(Icons.file_open),
              label: 'Import Stores',
            ),
          ],
        ),
      );
}
