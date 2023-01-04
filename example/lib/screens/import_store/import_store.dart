import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_sharing/fmtc_plus_sharing.dart';

class ImportStorePopup extends StatefulWidget {
  const ImportStorePopup({Key? key}) : super(key: key);

  @override
  State<ImportStorePopup> createState() => _ImportStorePopupState();
}

class _ImportStorePopupState extends State<ImportStorePopup> {
  final List<ImportResult> importingStores = [];

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
                            [],
                      );
                      setState(() {});
                    },
                  )
                : FutureBuilder<ImportResultCategory>(
                    future: importingStores[i].result,
                    builder: (context, resultCategory) {
                      final result = importingStores[i];
                      return ListTile(
                        leading: resultCategory.data == null
                            ? const CircularProgressIndicator()
                            : resultCategory.data ==
                                    ImportResultCategory.successful
                                ? const Icon(
                                    Icons.done,
                                    color: Colors.green,
                                  )
                                : resultCategory.data ==
                                        ImportResultCategory.collision
                                    ? const Icon(
                                        Icons.merge_type,
                                        color: Colors.amber,
                                      )
                                    : const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                        title: Text(result.storeName),
                        subtitle: resultCategory.data ==
                                    ImportResultCategory.successful ||
                                resultCategory.data == null
                            ? null
                            : resultCategory.data ==
                                    ImportResultCategory.collision
                                ? const Text(
                                    'A store with the same name already exists. What would you like to do?',
                                  )
                                : const Text(
                                    'Unknown error. The database file may have been corrupted.',
                                  ),
                        trailing: resultCategory.data ==
                                ImportResultCategory.collision
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => setState(
                                      () => importingStores
                                        ..remove(importingStores[i])
                                        ..add(
                                          FMTC.instance.rootDirectory.import
                                              .manual(
                                            File(result.path),
                                            overwriteExistingStore: true,
                                          ),
                                        ),
                                    ),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Overwrite store',
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                      () => importingStores
                                          .remove(importingStores[i]),
                                    ),
                                    icon: const Icon(Icons.cancel),
                                    tooltip: 'Cancel import',
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
            separatorBuilder: (context, i) => i == importingStores.length - 1
                ? const Divider()
                : const SizedBox.shrink(),
          ),
        ),
      );
}
