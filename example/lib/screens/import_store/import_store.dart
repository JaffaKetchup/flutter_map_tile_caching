import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class ImportStorePopup extends StatefulWidget {
  const ImportStorePopup({Key? key}) : super(key: key);

  @override
  State<ImportStorePopup> createState() => _ImportStorePopupState();
}

class _ImportStorePopupState extends State<ImportStorePopup> {
  final Map<String, Future<bool>> importingStores = {};

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Import Stores'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: ListView.separated(
            itemCount: importingStores.length + 1,
            itemBuilder: (context, i) => i == importingStores.length
                ? ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Choose New Store(s)'),
                    subtitle:
                        const Text('Select any valid store files (.fmtc)'),
                    onTap: () async {
                      importingStores.addAll(
                        await FMTC.instance.rootDirectory.import.withGUI() ??
                            {},
                      );
                      setState(() {});
                    },
                  )
                : FutureBuilder<bool>(
                    future: importingStores.values.toList()[i],
                    builder: (context, successful) => ListTile(
                      leading: !successful.hasData
                          ? const CircularProgressIndicator()
                          : successful.data!
                              ? const Icon(Icons.done, color: Colors.green)
                              : const Icon(Icons.error, color: Colors.red),
                      title: Text(importingStores.keys.toList()[i]),
                      subtitle: successful.data ?? true
                          ? null
                          : const Text('Invalid input format'),
                    ),
                  ),
            separatorBuilder: (context, i) => i == importingStores.length - 1
                ? const Divider()
                : const SizedBox.shrink(),
          ),
        ),
      );
}
