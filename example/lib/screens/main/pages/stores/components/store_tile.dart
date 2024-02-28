import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../../../store_editor/store_editor.dart';
import 'stat_display.dart';

class StoreTile extends StatefulWidget {
  StoreTile({
    required this.storeName,
  }) : super(key: ValueKey(storeName));

  final String storeName;

  @override
  State<StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<StoreTile> {
  bool _deletingProgress = false;
  bool _emptyingProgress = false;
  bool _exportingProgress = false;

  @override
  Widget build(BuildContext context) => Selector<GeneralProvider, String?>(
        selector: (context, provider) => provider.currentStore,
        builder: (context, currentStore, child) {
          final store = FMTCStore(widget.storeName);
          final isCurrentStore = currentStore == widget.storeName;

          return ExpansionTile(
            title: Text(
              widget.storeName,
              style: TextStyle(
                fontWeight:
                    isCurrentStore ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: _deletingProgress ? const Text('Deleting...') : null,
            initiallyExpanded: isCurrentStore,
            children: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: FutureBuilder(
                            future: store.manage.ready,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const UnconstrainedBox(
                                  child: CircularProgressIndicator.adaptive(),
                                );
                              }

                              if (!snapshot.data!) {
                                return const Wrap(
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 24,
                                  runSpacing: 12,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      size: 38,
                                    ),
                                    Text(
                                      'Invalid/missing store',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              }

                              return FutureBuilder(
                                future: store.stats.all,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const UnconstrainedBox(
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    );
                                  }

                                  return Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    runAlignment: WrapAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 32,
                                    runSpacing: 16,
                                    children: [
                                      SizedBox.square(
                                        dimension: 160,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: FutureBuilder(
                                            future: store.stats.tileImage(
                                              gaplessPlayback: true,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState !=
                                                  ConnectionState.done) {
                                                return const UnconstrainedBox(
                                                  child:
                                                      CircularProgressIndicator
                                                          .adaptive(),
                                                );
                                              }

                                              if (snapshot.data == null) {
                                                return const Icon(
                                                  Icons.grid_view_rounded,
                                                  size: 38,
                                                );
                                              }

                                              return snapshot.data!;
                                            },
                                          ),
                                        ),
                                      ),
                                      Wrap(
                                        alignment: WrapAlignment.spaceEvenly,
                                        runAlignment: WrapAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 64,
                                        children: [
                                          StatDisplay(
                                            statistic: snapshot.data!.length
                                                .toString(),
                                            description: 'tiles',
                                          ),
                                          StatDisplay(
                                            statistic:
                                                (snapshot.data!.size * 1024)
                                                    .asReadableSize,
                                            description: 'size',
                                          ),
                                          StatDisplay(
                                            statistic:
                                                snapshot.data!.hits.toString(),
                                            description: 'hits',
                                          ),
                                          StatDisplay(
                                            statistic: snapshot.data!.misses
                                                .toString(),
                                            description: 'misses',
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox.square(dimension: 8),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            runAlignment: WrapAlignment.spaceEvenly,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            children: [
                              IconButton(
                                icon: _deletingProgress
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 3,
                                      )
                                    : Icon(
                                        Icons.delete_forever,
                                        color:
                                            isCurrentStore ? null : Colors.red,
                                      ),
                                tooltip: 'Delete Store',
                                onPressed: isCurrentStore || _deletingProgress
                                    ? null
                                    : () async {
                                        setState(() {
                                          _deletingProgress = true;
                                          _emptyingProgress = true;
                                        });
                                        await FMTCStore(widget.storeName)
                                            .manage
                                            .delete();
                                      },
                              ),
                              IconButton(
                                icon: _emptyingProgress
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 3,
                                      )
                                    : const Icon(Icons.delete),
                                tooltip: 'Empty Store',
                                onPressed: _emptyingProgress
                                    ? null
                                    : () async {
                                        setState(
                                          () => _emptyingProgress = true,
                                        );
                                        await FMTCStore(widget.storeName)
                                            .manage
                                            .reset();
                                        setState(
                                          () => _emptyingProgress = false,
                                        );
                                      },
                              ),
                              IconButton(
                                icon: _exportingProgress
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 3,
                                      )
                                    : const Icon(
                                        Icons.send_time_extension_rounded,
                                      ),
                                tooltip: 'Export Store',
                                onPressed: _exportingProgress
                                    ? null
                                    : () async {
                                        // TODO: Implement
                                        /* setState(
                                                    () => _exportingProgress = true,
                                                  );
                                                  final bool result = await _store
                                                      .export
                                                      .withGUI(context: context);
                                                  setState(
                                                    () =>
                                                        _exportingProgress = false,
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          result
                                                              ? 'Exported Sucessfully'
                                                              : 'Export Cancelled',
                                                        ),
                                                      ),
                                                    );
                                                  }*/
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Store',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<String>(
                                    builder: (BuildContext context) =>
                                        StoreEditorPopup(
                                      existingStoreName: widget.storeName,
                                      isStoreInUse: isCurrentStore,
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.done,
                                  color: isCurrentStore ? Colors.green : null,
                                ),
                                tooltip: 'Use Store',
                                onPressed: isCurrentStore
                                    ? null
                                    : () {
                                        context.read<GeneralProvider>()
                                          ..currentStore = widget.storeName
                                          ..resetMap();
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}
