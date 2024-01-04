import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_sharing/fmtc_plus_sharing.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../../../store_editor/store_editor.dart';
import 'stat_display.dart';

class StoreTile extends StatefulWidget {
  const StoreTile({
    super.key,
    required this.context,
    required this.storeName,
  });

  final BuildContext context;
  final String storeName;

  @override
  State<StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<StoreTile> {
  Future<String>? _length;
  Future<String>? _size;
  Future<String>? _hits;
  Future<String>? _misses;
  Future<Image?>? _image;

  bool _deletingProgress = false;
  bool _emptyingProgress = false;
  bool _exportingProgress = false;

  late final _store = FMTC.instance(widget.storeName);

  void _loadStatistics() {
    final stats = _store.stats.all;

    _length = stats.then((s) => s.length.toString());
    _size = stats.then((s) => (s.size * 1024).asReadableSize);
    _hits = stats.then((s) => s.hits.toString());
    _misses = stats.then((s) => s.misses.toString());

    _image = _store.manage.tileImage(size: 125);

    setState(() {});
  }

  List<FutureBuilder<String>> get stats => [
        FutureBuilder<String>(
          future: _length,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.connectionState != ConnectionState.done
                ? null
                : snapshot.data,
            description: 'Total Tiles',
          ),
        ),
        FutureBuilder<String>(
          future: _size,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.connectionState != ConnectionState.done
                ? null
                : snapshot.data,
            description: 'Total Size',
          ),
        ),
        FutureBuilder<String>(
          future: _hits,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.connectionState != ConnectionState.done
                ? null
                : snapshot.data,
            description: 'Cache Hits',
          ),
        ),
        FutureBuilder<String>(
          future: _misses,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.connectionState != ConnectionState.done
                ? null
                : snapshot.data,
            description: 'Cache Misses',
          ),
        ),
      ];

  IconButton deleteStoreButton({required bool isCurrentStore}) => IconButton(
        icon: _deletingProgress
            ? const CircularProgressIndicator(
                strokeWidth: 3,
              )
            : Icon(
                Icons.delete_forever,
                color: isCurrentStore ? null : Colors.red,
              ),
        tooltip: 'Delete Store',
        onPressed: isCurrentStore || _deletingProgress
            ? null
            : () async {
                setState(() {
                  _deletingProgress = true;
                  _emptyingProgress = true;
                });
                await _store.manage.delete();
              },
      );

  @override
  Widget build(BuildContext context) => Consumer<GeneralProvider>(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder<Image?>(
              future: _image,
              builder: (context, snapshot) => snapshot.data == null
                  ? const SizedBox(
                      height: 125,
                      width: 125,
                      child: Icon(Icons.help_outline, size: 36),
                    )
                  : snapshot.data!,
            ),
            if (MediaQuery.sizeOf(context).width > 675)
              ...stats
            else
              Column(children: stats),
          ],
        ),
        builder: (context, provider, statistics) {
          final bool isCurrentStore = provider.currentStore == widget.storeName;

          return ExpansionTile(
            title: Text(
              widget.storeName,
              style: TextStyle(
                fontWeight:
                    isCurrentStore ? FontWeight.bold : FontWeight.normal,
                color: _store.manage.ready == false ? Colors.red : null,
              ),
            ),
            subtitle: _deletingProgress ? const Text('Deleting...') : null,
            leading: _store.manage.ready == false
                ? const Icon(
                    Icons.error,
                    color: Colors.red,
                  )
                : null,
            onExpansionChanged: (e) {
              if (e) _loadStatistics();
            },
            children: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 10),
                  child: _store.manage.ready
                      ? Column(
                          children: [
                            statistics!,
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                deleteStoreButton(
                                  isCurrentStore: isCurrentStore,
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
                                          await _store.manage.reset();
                                          setState(
                                            () => _emptyingProgress = false,
                                          );

                                          _loadStatistics();
                                        },
                                ),
                                IconButton(
                                  icon: _exportingProgress
                                      ? const CircularProgressIndicator(
                                          strokeWidth: 3,
                                        )
                                      : const Icon(Icons.upload_file_rounded),
                                  tooltip: 'Export Store',
                                  onPressed: _exportingProgress
                                      ? null
                                      : () async {
                                          setState(
                                            () => _exportingProgress = true,
                                          );
                                          final bool result = await _store
                                              .export
                                              .withGUI(context: context);
                                          setState(
                                            () => _exportingProgress = false,
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
                                          }
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
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Force Refresh Statistics',
                                  onPressed: _loadStatistics,
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
                                          provider
                                            ..currentStore = widget.storeName
                                            ..resetMap();
                                        },
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, size: 34),
                                Icon(Icons.error, size: 34),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Invalid Store',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              "This store's directory structure appears to have been corrupted. You must delete the store to resolve the issue.",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            deleteStoreButton(isCurrentStore: isCurrentStore),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      );
}
