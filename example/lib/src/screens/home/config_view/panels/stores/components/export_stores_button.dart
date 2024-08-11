import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../state/export_selection_provider.dart';

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
              'tiles from a single URL template. This is not a limitation '
              'with FMTC.\nAdditionally, FMTC supports changing the '
              'read/write behaviour for all unspecified stores, but this '
              'is not represented wihtin this app.',
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

    late final String filePath;
    if (Platform.isAndroid || Platform.isIOS) {
      final dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null) return;
      filePath = p.join(
        dirPath,
        'export ($fileNameTime).fmtc',
      );
    } else {
      final intermediateFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Stores',
        fileName: 'export ($fileNameTime).fmtc',
        type: FileType.custom,
        allowedExtensions: ['fmtc'],
      );
      if (intermediateFilePath == null) return;
      filePath = intermediateFilePath;
    }

    final selectedType = await FileSystemEntity.type(filePath);

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
      case FileSystemEntityType.directory:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(invalidTypeSnackbar);
        return;
      case FileSystemEntityType.file:
        if ((Platform.isAndroid || Platform.isIOS) &&
            (await showOverwriteConfirmationDialog(context) ?? false)) return;
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
    await FMTCRoot.external(pathToArchive: filePath)
        .export(storeNames: provider.selectedStores);

    provider.clearSelectedStores();

    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          'Export complete (in ${DateTime.timestamp().difference(startTime)})',
        ),
      ),
    );
  }
}

class _ExportingProgressDialog extends StatelessWidget {
  const _ExportingProgressDialog();

  @override
  Widget build(BuildContext context) => const AlertDialog.adaptive(
        icon: Icon(Icons.send_and_archive),
        title: Text('Export in progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator.adaptive(),
            SizedBox(height: 12),
            Text(
              "Please don't close this dialog or leave the app.\nThe operation "
              "will continue if the dialog is closed.\nWe'll let you know once "
              "we're done.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
