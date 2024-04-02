import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../shared/components/loading_indicator.dart';
import 'components/directory_selected.dart';
import 'components/export.dart';
import 'components/import.dart';
import 'components/no_path_selected.dart';
import 'components/path_picker.dart';

class ExportImportPopup extends StatefulWidget {
  const ExportImportPopup({super.key});

  @override
  State<ExportImportPopup> createState() => _ExportImportPopupState();
}

class _ExportImportPopupState extends State<ExportImportPopup> {
  final pathController = TextEditingController();

  final selectedStores = <String>{};
  Future<FileSystemEntityType>? typeOfPath;
  bool forceOverrideExisting = false;
  ImportConflictStrategy selectedConflictStrategy = ImportConflictStrategy.skip;
  bool isProcessing = false;

  void onPathChanged({required bool forceOverrideExisting}) => setState(() {
        this.forceOverrideExisting = forceOverrideExisting;
        typeOfPath = FileSystemEntity.type(pathController.text);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Export/Import Stores'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pathController,
                        decoration: const InputDecoration(
                          label: Text('Path To Archive'),
                          hintText: 'folder/archive.fmtc',
                          isDense: true,
                        ),
                        onEditingComplete: () =>
                            onPathChanged(forceOverrideExisting: false),
                      ),
                    ),
                    const SizedBox.square(dimension: 12),
                    PathPicker(
                      pathController: pathController,
                      onPathChanged: onPathChanged,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: pathController.text != '' && !isProcessing
                    ? SizedBox(
                        width: double.infinity,
                        child: FutureBuilder(
                          future: typeOfPath,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LoadingIndicator(
                                'Checking whether the path exists',
                              );
                            }

                            if (snapshot.data! ==
                                    FileSystemEntityType.notFound ||
                                forceOverrideExisting) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  left: 12,
                                  right: 12,
                                ),
                                child: Export(
                                  selectedStores: selectedStores,
                                ),
                              );
                            }

                            if (snapshot.data! != FileSystemEntityType.file) {
                              return const DirectorySelected();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 24,
                                left: 12,
                                right: 12,
                              ),
                              child: Import(
                                path: pathController.text,
                                changeForceOverrideExisting: onPathChanged,
                                conflictStrategy: selectedConflictStrategy,
                                changeConflictStrategy: (c) => setState(
                                  () => selectedConflictStrategy = c,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : pathController.text == ''
                        ? const NoPathSelected()
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator.adaptive(),
                                SizedBox(height: 12),
                                Text(
                                  'Exporting your stores, tiles, and metadata',
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'This could take a while, please be patient',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: FutureBuilder(
          future: typeOfPath,
          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                (snapshot.data! != FileSystemEntityType.file &&
                    snapshot.data! != FileSystemEntityType.notFound)) {
              return const SizedBox.shrink();
            }

            late final bool isExporting;
            late final Icon icon;
            if (snapshot.data! == FileSystemEntityType.notFound) {
              icon = const Icon(Icons.save);
              isExporting = true;
            } else if (snapshot.data! == FileSystemEntityType.file &&
                forceOverrideExisting) {
              icon = const Icon(Icons.save_as);
              isExporting = true;
            } else {
              icon = const Icon(Icons.file_open_rounded);
              isExporting = false;
            }

            return FloatingActionButton(
              heroTag: 'importExport',
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (isExporting) {
                        setState(() => isProcessing = true);
                        final stopwatch = Stopwatch()..start();
                        await FMTCRoot.external(
                          pathToArchive: pathController.text,
                        ).export(
                          storeNames: selectedStores.toList(),
                        );
                        stopwatch.stop();
                        if (context.mounted) {
                          final elapsedTime =
                              (stopwatch.elapsedMilliseconds / 1000)
                                  .toStringAsFixed(1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully exported stores (in $elapsedTime '
                                'secs)',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        setState(() => isProcessing = true);
                        final stopwatch = Stopwatch()..start();
                        final importResult = FMTCRoot.external(
                          pathToArchive: pathController.text,
                        ).import(
                          strategy: selectedConflictStrategy,
                        );
                        unawaited(importResult.storesToStates.then(print));
                        final numImportedTiles = await importResult.complete;
                        stopwatch.stop();
                        if (context.mounted) {
                          final elapsedTime =
                              (stopwatch.elapsedMilliseconds / 1000)
                                  .toStringAsFixed(1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully imported $numImportedTiles tiles '
                                '(in $elapsedTime secs)',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
              child: isProcessing
                  ? const SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : icon,
            );
          },
        ),
      );
}
