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

  late final _store = FMTC.instance(widget.storeName);

  void _loadStatistics() {
    _tiles = _store.stats.storeLengthAsync.then((l) => l.toString());
    _size = _store.stats.storeSizeAsync.then((s) => (s * 1024).asReadableSize);
    _cacheHits = _store.stats.cacheHitsAsync.then((h) => h.toString());
    _cacheMisses = _store.stats.cacheMissesAsync.then((m) => m.toString());
    _image = _store.manage.tileImageAsync(randomRange: 20, size: 125);

    setState(() {});
  }

  List<Widget> get stats => [
        FutureBuilder<String>(
          future: _tiles,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.data,
            description: 'Total Tiles',
          ),
        ),
        FutureBuilder<String>(
          future: _size,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.data,
            description: 'Total Size',
          ),
        ),
        FutureBuilder<String>(
          future: _cacheHits,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.data,
            description: 'Cache Hits',
          ),
        ),
        FutureBuilder<String>(
          future: _cacheMisses,
          builder: (context, snapshot) => StatDisplay(
            statistic: snapshot.data,
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
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_forever,
                              color: isCurrentStore ? null : Colors.red,
                            ),
                            tooltip: 'Delete Store',
                            onPressed: isCurrentStore
                                ? null
                                : () async {
                                    setState(() => _deletingProgress = true);
                                    await _store.manage.deleteAsync();
                                  },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Empty Store',
                            onPressed: () async {
                              setState(() => _deletingProgress = true);
                              await _store.manage.resetAsync();
                              setState(() => _deletingProgress = false);
                              _loadStatistics();
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
                            tooltip: 'Refresh Statistics',
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
                  ),
                ),
              ),
            ],
          );
        },
      );
}
