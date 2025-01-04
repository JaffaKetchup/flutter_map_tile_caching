import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../../../../../../shared/misc/store_metadata_keys.dart';
import '../../../../../../../../../../shared/state/general_provider.dart';
import '../../../../../../../../../store_editor/store_editor.dart';
import '../../../state/export_selection_provider.dart';
import 'components/browse_store_strategy_selector/browse_store_strategy_selector.dart';
import 'components/store_empty_deletion_dialog.dart';

part 'components/trailing.dart';

class StoreTile extends StatefulWidget {
  const StoreTile({
    super.key,
    required this.storeName,
    required this.stats,
    required this.metadata,
    required this.tileImage,
    required this.useCompactLayout,
  });

  final String storeName;
  final Future<({int hits, int length, int misses, double size})> stats;
  final Future<Map<String, String>> metadata;
  final Future<Image?> tileImage;
  final bool useCompactLayout;

  @override
  State<StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<StoreTile> {
  bool _isToolsVisible = false;
  bool _isEmptying = false;
  bool _isDeleting = false;
  Timer? _toolsAutoHiderTimer;

  @override
  void dispose() {
    _toolsAutoHiderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: FutureBuilder(
            future: widget.metadata,
            builder: (context, metadataSnapshot) {
              final matchesUrl = metadataSnapshot.data != null &&
                  context.select<GeneralProvider, String>(
                        (provider) => provider.urlTemplate,
                      ) ==
                      metadataSnapshot.data![StoreMetadataKeys.urlTemplate.key];

              final toolsChildren = [
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _exportStore,
                  icon: const Icon(Icons.send_and_archive),
                  visualDensity:
                      widget.useCompactLayout ? VisualDensity.compact : null,
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _editStore,
                  icon: const Icon(Icons.edit),
                  visualDensity:
                      widget.useCompactLayout ? VisualDensity.compact : null,
                ),
                const SizedBox(width: 4),
                if (_isEmptying)
                  const IconButton(
                    onPressed: null,
                    icon: SizedBox.square(
                      dimension: 18,
                      child: Center(
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: _emptyDeleteStore,
                    icon: const Icon(Icons.delete),
                    visualDensity:
                        widget.useCompactLayout ? VisualDensity.compact : null,
                  ),
                const SizedBox(width: 4),
              ];

              return InkWell(
                onSecondaryTap: _showTools,
                child: ListTile(
                  title: Text(
                    widget.storeName,
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
                      child: RepaintBoundary(
                        child: FutureBuilder(
                          future: widget.tileImage,
                          builder: (context, snapshot) {
                            if (snapshot.data case final data?) return data;
                            return const Icon(Icons.filter_none);
                          },
                        ),
                      ),
                    ),
                  ),
                  trailing: _Trailing(
                    storeName: widget.storeName,
                    matchesUrl: matchesUrl,
                    isToolsVisible: _isToolsVisible,
                    isDeleting: _isDeleting,
                    useCompactLayout: widget.useCompactLayout,
                    toolsChildren: toolsChildren,
                  ),
                  onLongPress: _showTools,
                  onTap: _hideTools,
                ),
              );
            },
          ),
        ),
      );

  Future<void> _exportStore() async {
    context.read<ExportSelectionProvider>().addSelectedStore(widget.storeName);
    await _hideTools();
  }

  Future<void> _editStore() async {
    await Navigator.of(context).pushNamed(
      StoreEditorPopup.route,
      arguments: widget.storeName,
    );
    await _hideTools();
  }

  Future<void> _emptyDeleteStore() async {
    _toolsAutoHiderTimer?.cancel();

    final result = await showDialog<({Future<void> future, bool isDeleting})>(
      context: context,
      builder: (context) =>
          StoreEmptyDeletionDialog(storeName: widget.storeName),
    );

    if (result == null) {
      setState(() => _isToolsVisible = false);
      return;
    }

    if (result.isDeleting) {
      setState(() => _isDeleting = true);
      await result.future;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${widget.storeName}')),
      );
      return;
    }

    setState(() => _isEmptying = true);
    await result.future;
    setState(() => _isEmptying = false);
  }

  Future<void> _hideTools() async {
    setState(() => _isToolsVisible = false);
    _toolsAutoHiderTimer?.cancel();
    return Future.delayed(const Duration(milliseconds: 150));
  }

  void _showTools() {
    setState(() => _isToolsVisible = true);
    _toolsAutoHiderTimer = Timer(const Duration(seconds: 5), _hideTools);
  }
}
