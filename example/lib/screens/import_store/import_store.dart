import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_sharing/fmtc_plus_sharing.dart';

class ImportStorePopup extends StatefulWidget {
  const ImportStorePopup({super.key});

  @override
  State<ImportStorePopup> createState() => _ImportStorePopupState();
}

class _ImportStorePopupState extends State<ImportStorePopup> {
  final Map<String, _ImportStore> importStores = {};

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Import Stores'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: ListView.separated(
            itemCount: importStores.length + 1,
            itemBuilder: (context, i) {
              if (i == importStores.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Choose New Store(s)'),
                  subtitle: const Text('Select any valid store files (.fmtc)'),
                  onTap: () async {
                    importStores.addAll(
                      (await FMTC.instance.rootDirectory.import.withGUI(
                                collisionHandler: (s) {
                                  setState(
                                    () => importStores[s]!
                                        .needsCollisionResolution = true,
                                  );
                                  return importStores[s]!
                                      .collisionResolution
                                      .future;
                                },
                              ) ??
                              {})
                          .map(
                        (name, status) => MapEntry(
                          name,
                          _ImportStore(status, needsCollisionResolution: false),
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                );
              }

              final storeName = importStores.keys.toList()[i];
              return FutureBuilder<bool>(
                future: importStores[storeName]?.resultStatus,
                builder: (context, status) => FutureBuilder<bool>(
                  future: importStores[storeName]?.collisionResolution.future,
                  builder: (context, conflict) {
                    final isCollision =
                        importStores[storeName]!.needsCollisionResolution &&
                            conflict.data == null;
                    final isSuccessful = status.data == null || status.data!;
                    final isCancelled = conflict.data == false;

                    return ListTile(
                      leading: isCollision
                          ? const Icon(Icons.merge_type, color: Colors.amber)
                          : isSuccessful
                              ? const Icon(Icons.done, color: Colors.green)
                              : isCancelled
                                  ? const Icon(Icons.cancel)
                                  : const Icon(Icons.error, color: Colors.red),
                      title: Text(storeName),
                      subtitle: isCollision
                          ? const Text(
                              'A store with the same name already exists. What would you like to do?',
                            )
                          : isSuccessful
                              ? null
                              : Text(
                                  isCancelled
                                      ? 'Import cancelled due to collision.'
                                      : 'Import failed. The database file may have been corrupted.',
                                ),
                      trailing: isCollision
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => importStores[storeName]!
                                      .collisionResolution
                                      .complete(true),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Overwrite store',
                                ),
                                IconButton(
                                  onPressed: () => importStores[storeName]!
                                      .collisionResolution
                                      .complete(false),
                                  icon: const Icon(Icons.cancel),
                                  tooltip: 'Cancel import',
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              );
            },
            separatorBuilder: (context, i) => i == importStores.length - 1
                ? const Divider()
                : const SizedBox.shrink(),
          ),
        ),
      );
}

class _ImportStore {
  final Future<bool> resultStatus;
  bool needsCollisionResolution;
  Completer<bool> collisionResolution;

  _ImportStore(
    this.resultStatus, {
    required this.needsCollisionResolution,
  }) : collisionResolution = Completer();
}
