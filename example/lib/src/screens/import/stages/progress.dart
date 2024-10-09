import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class ImportProgressStage extends StatefulWidget {
  const ImportProgressStage({
    super.key,
    required this.fmtcExternal,
    required this.selectedStores,
    required this.conflictStrategy,
    required this.nextStage,
  });

  final RootExternal fmtcExternal;
  final Set<String> selectedStores;
  final ImportConflictStrategy conflictStrategy;
  final Completer<({int tiles, Duration duration})> nextStage;

  @override
  State<ImportProgressStage> createState() => _ImportProgressStageState();
}

class _ImportProgressStageState extends State<ImportProgressStage> {
  @override
  void initState() {
    super.initState();

    final start = DateTime.timestamp();
    widget.fmtcExternal
        .import(
          storeNames: widget.selectedStores.toList(),
          strategy: widget.conflictStrategy,
        )
        .complete
        .then(
          (tiles) => widget.nextStage.complete(
            (tiles: tiles, duration: DateTime.timestamp().difference(start)),
          ),
          onError: widget.nextStage.completeError,
        );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 64,
                  child: CircularProgressIndicator.adaptive(),
                ),
                Icon(Icons.file_open, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "We're importing your stores...",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This could take a while.\n'
              "We don't recommend leaving this screen. The import will "
              'continue, but performance could be affected.\n'
              'Closing the app will stop the import operation in an '
              'indeterminate (but stable) state.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
