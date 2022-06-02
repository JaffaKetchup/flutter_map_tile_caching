import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../shared/components/loading_indicator.dart';
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

    void _listStores() =>
        _stores = FMTC.instance.rootDirectory.stats.storesAvailableAsync;

    _listStores();
    FMTC.instance.rootDirectory.stats.watchChanges().listen((_) {
      if (mounted) {
        _listStores();
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
                FutureBuilder<List<StoreDirectory>>(
                  future: _stores,
                  builder: (context, snapshot) => snapshot.hasData
                      ? snapshot.data!.isEmpty
                          ? const EmptyIndicator()
                          : Expanded(
                              child: ListView.builder(
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) => StoreTile(
                                  context: context,
                                  storeName: snapshot.data![index].storeName,
                                  key:
                                      ValueKey(snapshot.data![index].storeName),
                                ),
                              ),
                            )
                      : const Expanded(
                          child: LoadingIndicator(
                            message: 'Loading Stores...',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<String>(
              builder: (BuildContext context) => const StoreEditorPopup(
                existingStoreName: null,
                isStoreInUse: false,
              ),
              fullscreenDialog: true,
            ),
          ),
          child: const Icon(Icons.create_new_folder),
        ),
      );
}
