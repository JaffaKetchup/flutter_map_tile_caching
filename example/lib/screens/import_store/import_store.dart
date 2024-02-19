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
                      (await FMTCRoot.import.withGUI(
                                collisionHandler: (fn, sn) {
                                  setState(
                                    () => importStores[fn]!.collisionInfo = [
                                      fn,
                                      sn,
                                    ],
                                  );
                                  return importStores[fn]!
                                      .collisionResolution
                                      .future;
                                },
                              ) ??
                              {})
                          .map(
                        (name, status) => MapEntry(
                          name,
                          _ImportStore(status, collisionInfo: null),
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                );
              }

              final filename = importStores.keys.toList()[i];
              return FutureBuilder<ImportResult>(
                future: importStores[filename]?.result,
                builder: (context, s1) => FutureBuilder<bool>(
                  future: importStores[filename]?.collisionResolution.future,
                  builder: (context, s2) {
                    final result = s1.data;
                    final conflict = s2.data;

                    T stateSwitcher<T>({
                      required T loading,
                      required T successful,
                      required T failed,
                      required T cancelled,
                      required T collided,
                    }) {
                      if (importStores[filename]!.collisionInfo != null &&
                          conflict == null) return collided;
                      if (conflict == false) return cancelled;
                      if (result == null) return loading;
                      return result.successful ? successful : failed;
                    }

                    final storeName = result?.storeName;

                    return ListTile(
                      leading: stateSwitcher(
                        loading: const CircularProgressIndicator.adaptive(),
                        successful: const Icon(Icons.done, color: Colors.green),
                        failed: const Icon(Icons.error, color: Colors.red),
                        cancelled: const Icon(Icons.cancel),
                        collided:
                            const Icon(Icons.merge_type, color: Colors.amber),
                      ),
                      title: Text(filename),
                      subtitle: stateSwitcher(
                        loading: const Text('Loading...'),
                        successful: Text('Imported as: $storeName'),
                        failed: null,
                        cancelled: null,
                        collided: Text(
                          'Collision with ${importStores[filename]!.collisionInfo?[1]}',
                        ),
                      ),
                      trailing: importStores[filename]!.collisionInfo != null &&
                              conflict == null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => importStores[filename]!
                                      .collisionResolution
                                      .complete(true),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Overwrite store',
                                ),
                                IconButton(
                                  onPressed: () => importStores[filename]!
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
  final Future<ImportResult> result;
  List<String>? collisionInfo;
  Completer<bool> collisionResolution;

  _ImportStore(
    this.result, {
    required this.collisionInfo,
  }) : collisionResolution = Completer();
}
