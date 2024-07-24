import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../../shared/misc/store_metadata_keys.dart';
import '../../../../../../shared/state/general_provider.dart';
import '../../../../../store_editor/store_editor.dart';
import 'store_read_write_behaviour_selector.dart';

class StoreTile extends StatefulWidget {
  const StoreTile({
    super.key,
    required this.store,
    required this.stats,
    required this.metadata,
    required this.tileImage,
  });

  final FMTCStore store;
  final Future<({int hits, int length, int misses, double size})> stats;
  final Future<Map<String, String>> metadata;
  final Future<Image?> tileImage;

  @override
  State<StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<StoreTile> {
  bool _toolsVisible = false;
  bool _toolsEmptyLoading = false;
  bool _toolsDeleteLoading = false;
  Timer? _toolsAutoHiderTimer;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Consumer<GeneralProvider>(
          builder: (context, provider, _) => FutureBuilder(
            future: widget.metadata,
            builder: (context, metadataSnapshot) {
              final matchesUrl = metadataSnapshot.data != null &&
                  provider.urlTemplate ==
                      metadataSnapshot.data![StoreMetadataKeys.urlTemplate.key];

              final toolsChildren = _toolsDeleteLoading
                  ? [
                      const Center(
                        child: SizedBox.square(
                          dimension: 25,
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                      ),
                    ]
                  : [
                      IconButton(
                        onPressed: _editStore,
                        icon: const Icon(Icons.edit),
                      ),
                      if (_toolsEmptyLoading)
                        const Center(
                          child: SizedBox.square(
                            dimension: 25,
                            child: Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: _emptyStore,
                          icon: const Icon(Icons.delete),
                        ),
                      IconButton(
                        onPressed: _deleteStore,
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                      ),
                    ];

              return InkWell(
                onSecondaryTap: _showTools,
                child: ListTile(
                  title: Text(
                    widget.store.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  subtitle: FutureBuilder(
                    future: widget.stats,
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.data case final stats?) {
                        return Text(
                          '${(stats.size * 1024).asReadableSize} | '
                          '${stats.length} tiles',
                        );
                      }
                      return const Text('Loading stats...');
                    },
                  ),
                  leading: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FutureBuilder(
                        future: widget.tileImage,
                        builder: (context, snapshot) {
                          if (snapshot.data case final data?) return data;
                          return const Icon(Icons.filter_none);
                        },
                      ),
                    ),
                  ),
                  trailing: IntrinsicWidth(
                    child: IntrinsicHeight(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: StoreReadWriteBehaviourSelector(
                              storeName: widget.store.storeName,
                              enabled: matchesUrl,
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: matchesUrl ? 0 : 1,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            child: IgnorePointer(
                              ignoring: matchesUrl,
                              child: SizedBox.expand(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(Icons.link_off, color: Colors.white),
                                      Text(
                                        'URL mismatch',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: _toolsVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            child: IgnorePointer(
                              ignoring: !_toolsVisible,
                              child: SizedBox.expand(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceDim,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: toolsChildren,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onLongPress: _showTools,
                  onTap: _hideTools,
                ),
              );
            },
          ),
        ),
      );

  Future<void> _editStore() async {
    await Navigator.of(context).pushNamed(
      StoreEditorPopup.route,
      arguments: widget.store.storeName,
    );
    await _hideTools();
  }

  Future<void> _emptyStore() async {
    _toolsAutoHiderTimer?.cancel();
    setState(() => _toolsEmptyLoading = true);
    await widget.store.manage.reset();
    await _hideTools();
    setState(() => _toolsEmptyLoading = false);
  }

  Future<void> _deleteStore() async {
    _toolsAutoHiderTimer?.cancel();
    setState(() => _toolsDeleteLoading = true);
    await widget.store.manage.delete();
  }

  Future<void> _hideTools() async {
    setState(() => _toolsVisible = false);
    _toolsAutoHiderTimer?.cancel();
    return Future.delayed(const Duration(milliseconds: 150));
  }

  void _showTools() {
    setState(() => _toolsVisible = true);
    _toolsAutoHiderTimer = Timer(const Duration(seconds: 5), _hideTools);
  }
}
