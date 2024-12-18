import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/export_selection_provider.dart';

part 'name_input_dialog.dart';
part 'progress_dialog.dart';

class ExportStoresButton extends StatelessWidget {
  const ExportStoresButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: double.infinity,
                      child: FilledButton.tonalIcon(
                        label: const Text('Export selected stores'),
                        icon: const Icon(Icons.send_and_archive),
                        onPressed: () => _export(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.cancel),
                    tooltip: 'Cancel export',
                    onPressed: () => context
                        .read<ExportSelectionProvider>()
                        .clearSelectedStores(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Within the example app, for simplicity, each store contains '
              'tiles from a single URL template. Additionally, only one tile '
              'layer with a single URL template can be used at any one time. '
              'These are not limitations with FMTC.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );

  Future<void> _export(BuildContext context) async {
    Future<bool?> showOverwriteConfirmationDialog(BuildContext context) =>
        showDialog(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text(
              'Overwrite existing file?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );

    final provider = context.read<ExportSelectionProvider>();
    final fileNameTime =
        DateTime.now().toString().split('.').first.replaceAll(':', '-');

    final String filePath;
    late final String tempDir;
    if (Platform.isAndroid || Platform.isIOS) {
      tempDir = p.join(
        (await getTemporaryDirectory()).absolute.path,
        'fmtc_export',
      );
      await Directory(tempDir).create(recursive: true);

      if (!context.mounted) {
        provider.clearSelectedStores();
        return;
      }

      final name = await showDialog(
        context: context,
        builder: (context) => _ExportingNameInputDialog(
          defaultName: 'export ($fileNameTime)',
          tempDir: tempDir,
        ),
      );
      if (name == null) return;

      filePath = p.join(tempDir, '$name.fmtc');
    } else {
      final intermediateFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Stores',
        fileName: 'export ($fileNameTime).fmtc',
        type: FileType.custom,
        allowedExtensions: ['fmtc'],
      );

      if (intermediateFilePath == null) return;
      final selectedType = await FileSystemEntity.type(intermediateFilePath);

      if (!context.mounted) {
        provider.clearSelectedStores();
        return;
      }

      const invalidTypeSnackbar = SnackBar(
        content: Text(
          'Cannot start export: must be a file or non-existent',
        ),
      );

      switch (selectedType) {
        case FileSystemEntityType.notFound:
          break;
        case FileSystemEntityType.file:
          if ((Platform.isAndroid || Platform.isIOS) &&
              (await showOverwriteConfirmationDialog(context) ?? false)) {
            return;
          }
        // ignore: no_default_cases
        default:
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(invalidTypeSnackbar);
          return;
      }

      filePath = intermediateFilePath;
    }

    if (!context.mounted) {
      provider.clearSelectedStores();
      return;
    }

    unawaited(
      showDialog(
        context: context,
        builder: (context) => const _ExportingProgressDialog(),
        barrierDismissible: false,
      ),
    );

    final startTime = DateTime.timestamp();
    final tiles = await FMTCRoot.external(pathToArchive: filePath)
        .export(storeNames: provider.selectedStores);

    provider.clearSelectedStores();

    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          'Exported $tiles tiles in '
          '${DateTime.timestamp().difference(startTime)}',
        ),
      ),
    );

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles([XFile(filePath)]);
      await Directory(tempDir).delete(recursive: true);
    }
  }
}
