import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'stages/complete.dart';
import 'stages/error.dart';
import 'stages/loading.dart';
import 'stages/progress.dart';
import 'stages/selection.dart';

class ImportPopup extends StatefulWidget {
  const ImportPopup({super.key});

  static const String route = '/import';

  static Future<void> start(BuildContext context) async {
    final pickerResult = Platform.isAndroid || Platform.isIOS
        ? FilePicker.platform.pickFiles()
        : FilePicker.platform.pickFiles(
            dialogTitle: 'Import Archive',
            type: FileType.custom,
            allowedExtensions: ['fmtc'],
          );
    final filePath = (await pickerResult)?.paths.single;

    if (filePath == null || !context.mounted) return;

    await Navigator.of(context).pushNamed(
      ImportPopup.route,
      arguments: filePath,
    );
  }

  @override
  State<ImportPopup> createState() => _ImportPopupState();
}

class _ImportPopupState extends State<ImportPopup> {
  RootExternal? fmtcExternal;

  int stage = 1;

  late Object error; // Stage 0

  late Map<String, bool> availableStores; // Stage 1 -> 2

  late Set<String> selectedStores; // Stage 2 -> 3
  late ImportConflictStrategy conflictStrategy; // Stage 2 -> 3

  late int importTilesResult; // Stage 3 -> 4
  late Duration importDuration; // Stage 3 -> 4

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    fmtcExternal ??= FMTCRoot.external(
      pathToArchive: ModalRoute.of(context)!.settings.arguments! as String,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: stage != 3,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "We don't recommend leaving this screen while the import is "
                  'in progress',
                ),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Import Archive'),
            automaticallyImplyLeading: stage != 3,
            elevation: 1,
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) => SlideTransition(
              position: (animation.value == 1
                      ? Tween(begin: const Offset(-1, 0), end: Offset.zero)
                      : Tween(begin: const Offset(1, 0), end: Offset.zero))
                  .animate(animation),
              child: child,
            ),
            child: switch (stage) {
              0 => ImportErrorStage(error: error),
              1 => ImportLoadingStage(
                  fmtcExternal: fmtcExternal!,
                  nextStage: Completer()
                    ..future.then(
                      (availableStores) => setState(() {
                        this.availableStores = availableStores;
                        stage++;
                      }),
                      onError: (err) => setState(() {
                        error = err;
                        stage = 0;
                      }),
                    ),
                ),
              2 => ImportSelectionStage(
                  fmtcExternal: fmtcExternal!,
                  availableStores: availableStores,
                  nextStage: (selectedStores, conflictStrategy) => setState(() {
                    this.selectedStores = selectedStores;
                    this.conflictStrategy = conflictStrategy;
                    stage++;
                  }),
                ),
              3 => ImportProgressStage(
                  fmtcExternal: fmtcExternal!,
                  selectedStores: selectedStores,
                  conflictStrategy: conflictStrategy,
                  nextStage: Completer()
                    ..future.then(
                      (result) => setState(() {
                        importTilesResult = result.tiles;
                        importDuration = result.duration;
                        stage++;
                      }),
                      onError: (err) => setState(() {
                        error = err;
                        stage = 0;
                      }),
                    ),
                ),
              4 => ImportCompleteStage(
                  tiles: importTilesResult,
                  duration: importDuration,
                ),
              _ => throw UnimplementedError(),
            },
          ),
        ),
      );
}
