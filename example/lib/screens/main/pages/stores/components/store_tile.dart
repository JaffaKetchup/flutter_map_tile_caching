import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/components/size_formatter.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../../../store_editor/store_editor.dart';
import 'stat_display.dart';

class StoreTile extends StatefulWidget {
  const StoreTile({
    Key? key,
    required this.context,
    required this.storeName,
  }) : super(key: key);

  final BuildContext context;
  final String storeName;

  @override
  State<StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<StoreTile> {
  Future<String>? _tiles;
  Future<String>? _size;
  Future<String>? _cacheHits;
  Future<String>? _cacheMisses;
  Future<Image?>? _image;

  bool _deletingProgress = false;
  bool _emptyingProgress = false;
  bool _exportingProgress = false;

  late final _store = FMTC.instance(widget.storeName);

  void _loadStatistics({bool withoutCachedStatistics = false}) {
    final stats =
        !withoutCachedStatistics ? _store.stats : _store.stats.noCache;

    _tiles = stats.storeLengthAsync.then((l) => l.toString());
    _size = stats.storeSizeAsync.then((s) => (s * 1024).asReadableSize);
    _cacheHits = stats.cacheHitsAsync.then((h) => h.toString());
    _cacheMisses = stats.cacheMissesAsync.then((m) => m.toString());
    _image = _store.manage.tileImageAsync(randomRange: 20, size: 125);

    setState(() {});
  }

  List<Widget> get stats => [
        FutureBuilder<String>(
          future: _tiles,
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
          future: _cacheHits,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.connectionState != ConnectionState.done
                ? null
                : snapshot.data,
            description: 'Cache Hits',
          ),
        ),
        FutureBuilder<String>(
          future: _cacheMisses,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.connectionState != ConnectionState.done
                ? null
                : snapshot.data,
            description: 'Cache Misses',
          ),
        ),
      ];

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
            if (MediaQuery.of(context).size.width > 675)
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
              ),
            ),
            subtitle: _deletingProgress ? const Text('Deleting...') : null,
            onExpansionChanged: (e) {
              if (e) _loadStatistics();
            },
            children: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 10),
                  child: Column(
                    children: [
                      statistics!,
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
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
                                    await _store.manage.deleteAsync();
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
                                    setState(() => _emptyingProgress = true);
                                    await _store.manage.resetAsync();

                                    setState(() => _emptyingProgress = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Finished Emptying'),
                                        ),
                                      );
                                    }

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
                                    setState(() => _exportingProgress = true);
                                    final bool result = await _store.export
                                        .withGUI(context: context);

                                    setState(() => _exportingProgress = false);
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
                            onPressed: () =>
                                _loadStatistics(withoutCachedStatistics: true),
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
                  ),
                ),
              ),
            ],
          );
        },
      );
}
