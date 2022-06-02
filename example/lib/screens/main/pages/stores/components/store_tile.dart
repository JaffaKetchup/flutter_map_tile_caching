import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/components/stat.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../../../store_editor/store_editor.dart';

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
  Future<Image?>? _image;
  Future<String>? _tiles;
  Future<String>? _size;

  bool _deletingProgress = false;

  late final _store = FMTC.instance(widget.storeName);

  void _loadStatistics() {
    _image = _store.stats.coverImageAsync(random: false, size: 62.5);
    _tiles = _store.stats.storeLengthAsync.then((l) => l.toString());
    _size = _store.stats.storeSizeAsync
        .then((s) => '${(s / 1000).toStringAsFixed(2)}MB');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Consumer<GeneralProvider>(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder<Image?>(
              future: _image,
              builder: (context, snapshot) => snapshot.data == null
                  ? const SizedBox(
                      height: 62.5,
                      width: 62.5,
                      child: Icon(Icons.help_outline, size: 36),
                    )
                  : snapshot.data!,
            ),
            FutureBuilder<String>(
              future: _tiles,
              builder: (context, snapshot) => Stat(
                statistic: snapshot.data,
                description: 'Total Tiles',
              ),
            ),
            FutureBuilder<String>(
              future: _size,
              builder: (context, snapshot) => Stat(
                statistic: snapshot.data,
                description: 'Total Size',
              ),
            ),
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
