import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class ImportLoadingStage extends StatefulWidget {
  const ImportLoadingStage({
    super.key,
    required this.fmtcExternal,
    required this.nextStage,
  });

  final RootExternal fmtcExternal;
  final Completer<Map<String, bool>> nextStage;

  @override
  State<ImportLoadingStage> createState() => _ImportLoadingStageState();
}

class _ImportLoadingStageState extends State<ImportLoadingStage> {
  @override
  void initState() {
    super.initState();

    widget.fmtcExternal.listStores
        .then(
          (stores) async => Map.fromEntries(
            await Future.wait(
              stores
                  .map(
                    (storeName) async => MapEntry(
                      storeName,
                      await FMTCStore(storeName).manage.ready,
                    ),
                  )
                  .toList(),
            ),
          ),
        )
        .then(
          widget.nextStage.complete,
          onError: widget.nextStage.completeError,
        );
  }

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 64,
                  child: CircularProgressIndicator.adaptive(),
                ),
                Icon(Icons.file_open, size: 32),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "We're just preparing the archive for you...\nThis could "
              'take a few moments.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
