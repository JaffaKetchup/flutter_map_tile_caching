import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportPopup extends StatefulWidget {
  const ExportPopup({super.key});

  static const String route = '/export';

  @override
  State<ExportPopup> createState() => _ExportPopupState();
}

class _ExportPopupState extends State<ExportPopup> {
  late final _inputController = TextEditingController();

  final _availableStores = FMTCRoot.stats.storesAvailable;

  final _selectedStores = <FMTCStore>{};

  bool _isExporting = false;
  bool _isVerifying = false;
  bool _isInvalid = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Export Stores'),
        ),
        body: FutureBuilder(
          future: _availableStores,
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 12),
                    Text(
                      'Loading stores',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            final stores = snapshot.requireData;

            assert(
              stores.isNotEmpty,
              'This route should not be navigable if there are no stores',
            );

            final isMobilePlatform = Platform.isAndroid || Platform.isIOS;

            final exportLoader = Padding(
              key: const ValueKey('exportLoader'),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 64,
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      Icon(Icons.send_and_archive, size: 32),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exporting selected stores...',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Please don't close this dialog or leave the app.\n"
                          'The operation will continue if the dialog is '
                          "closed.\nWe'll let you know once we're done.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final pathInput = Padding(
              key: const ValueKey('pathInput'),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _inputController,
                          enabled: !_isVerifying,
                          decoration: InputDecoration(
                            suffixText: isMobilePlatform ? '.fmtc' : null,
                            filled: true,
                            label: isMobilePlatform
                                ? const Text('Archive name')
                                : const Text('Archive path'),
                            errorText: _isInvalid ? 'Invalid name' : null,
                          ),
                          onChanged: (_) => setState(() => _isInvalid = false),
                        ),
                      ),
                      if (!isMobilePlatform)
                        SizedBox(
                          height: 38,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.centerRight,
                            child: ValueListenableBuilder(
                              valueListenable: _inputController,
                              builder: (context, controller, _) {
                                if (controller.text.isEmpty) {
                                  return FilledButton.icon(
                                    onPressed: _launchPlatformPicker,
                                    icon: const Icon(Icons.note_add),
                                    label: const Text('Select file'),
                                  );
                                } else {
                                  return IconButton.filledTonal(
                                    onPressed: _launchPlatformPicker,
                                    icon: const Icon(Icons.note_add),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) => Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 38,
                        width:
                            constraints.maxWidth > 500 ? 250 : double.infinity,
                        child: ValueListenableBuilder(
                          valueListenable: _inputController,
                          builder: (context, controller, _) {
                            final enabled = _selectedStores.isEmpty ||
                                _isVerifying ||
                                controller.text.isEmpty;

                            return FilledButton.icon(
                              onPressed: enabled ? null : _verifyAndExport,
                              icon: _isVerifying
                                  ? null
                                  : const Icon(Icons.send_and_archive),
                              label: _isVerifying
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'Create archive & '
                                      '${isMobilePlatform ? 'share' : 'save'}',
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            return Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: stores.length,
                      itemBuilder: (context, index) {
                        final store = stores[index];

                        return CheckboxListTile.adaptive(
                          title: Text(store.storeName),
                          value: _selectedStores.contains(store),
                          onChanged: _isVerifying
                              ? null
                              : (value) {
                                  if (value!) {
                                    _selectedStores.add(store);
                                  } else {
                                    _selectedStores.remove(store);
                                  }
                                  setState(() {});
                                },
                        );
                      },
                    ),
                  ),
                ),
                ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: (animation.value == 1
                                ? Tween(
                                    begin: const Offset(-1, 0),
                                    end: Offset.zero,
                                  )
                                : Tween(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ))
                            .animate(animation),
                        child: child,
                      ),
                      child: _isExporting ? exportLoader : pathInput,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Future<void> _launchPlatformPicker() async {
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Stores',
      fileName: 'export.fmtc',
      type: FileType.custom,
      allowedExtensions: ['fmtc'],
    );
    if (filePath == null) return;
    _inputController.text = filePath;
    setState(() => _isInvalid = false);
  }

  Future<void> _verifyAndExport() async {
    void errorOut() {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isInvalid = true;
      });
    }

    setState(() => _isVerifying = true);

    late final String path;

    if (Platform.isAndroid || Platform.isIOS) {
      final tempDir =
          p.join((await getTemporaryDirectory()).absolute.path, 'fmtc_export');
      path = p.join(tempDir, '${_inputController.text}.fmtc.tmp');
    } else {
      path = _inputController.text;

      late final FileSystemEntityType selectedType;
      try {
        selectedType = await FileSystemEntity.type(path);
      } on FileSystemException {
        return errorOut();
      }
      if (selectedType != FileSystemEntityType.notFound &&
          selectedType != FileSystemEntityType.file) {
        return errorOut();
      }
    }

    final file = File(path);
    try {
      await file.create(recursive: true);
      await file.delete();
    } on FileSystemException {
      return errorOut();
    }

    if (!mounted) return;
    setState(() => _isExporting = true);

    final stopwatch = Stopwatch()..start();

    final tilesCount = await FMTCRoot.external(pathToArchive: path).export(
      storeNames:
          _selectedStores.map((s) => s.storeName).toList(growable: false),
    );

    stopwatch.stop();

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles([XFile(path)]);
      await File(path).delete(recursive: true);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('Exported $tilesCount tiles in ${stopwatch.elapsed}'),
      ),
    );
  }
}
