import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class ImportSelectionStage extends StatefulWidget {
  const ImportSelectionStage({
    super.key,
    required this.fmtcExternal,
    required this.availableStores,
    required this.nextStage,
  });

  final RootExternal fmtcExternal;
  final Map<String, bool> availableStores;
  final void Function(
    Set<String> selectedStores,
    ImportConflictStrategy conflictStrategy,
  ) nextStage;

  @override
  State<ImportSelectionStage> createState() => _ImportSelectionStageState();
}

class _ImportSelectionStageState extends State<ImportSelectionStage> {
  late final Set<String> selectedStores = widget.availableStores.keys.toSet();
  ImportConflictStrategy conflictStrategy = ImportConflictStrategy.rename;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                itemCount: widget.availableStores.length,
                itemBuilder: (context, index) {
                  final storeName =
                      widget.availableStores.keys.elementAt(index);
                  final collision =
                      widget.availableStores.values.elementAt(index);

                  return CheckboxListTile.adaptive(
                    title: Text(storeName),
                    subtitle: Text(collision ? 'Collision' : 'No collision'),
                    value: !(collision &&
                            conflictStrategy == ImportConflictStrategy.skip) &&
                        selectedStores.contains(storeName),
                    onChanged: collision &&
                            conflictStrategy == ImportConflictStrategy.skip
                        ? null
                        : (v) => setState(
                              () => (v!
                                      ? selectedStores.add
                                      : selectedStores.remove)
                                  .call(storeName),
                            ),
                  );
                },
              ),
            ),
          ),
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton(
                      isExpanded: true,
                      value: conflictStrategy,
                      items: ImportConflictStrategy.values.map(
                        (e) {
                          final icon = switch (e) {
                            ImportConflictStrategy.merge => Icons.merge_rounded,
                            ImportConflictStrategy.rename => Icons.edit_rounded,
                            ImportConflictStrategy.replace =>
                              Icons.save_as_rounded,
                            ImportConflictStrategy.skip =>
                              Icons.skip_next_rounded,
                          };
                          final text = switch (e) {
                            ImportConflictStrategy.merge =>
                              'Merge existing & conflicting stores',
                            ImportConflictStrategy.rename =>
                              'Rename conflicting stores (append date & time)',
                            ImportConflictStrategy.replace =>
                              'Replace existing stores',
                            ImportConflictStrategy.skip =>
                              'Skip conflicting stores',
                          };

                          return DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                Icon(icon),
                                const SizedBox(width: 12),
                                Expanded(child: Text(text)),
                              ],
                            ),
                          );
                        },
                      ).toList(growable: false),
                      onChanged: (c) => setState(() => conflictStrategy = c!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: selectedStores.isNotEmpty &&
                              (conflictStrategy !=
                                      ImportConflictStrategy.skip ||
                                  selectedStores
                                      .whereNot(
                                        (store) =>
                                            widget.availableStores[store]!,
                                      )
                                      .isNotEmpty)
                          ? () =>
                              widget.nextStage(selectedStores, conflictStrategy)
                          : null,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Start Import'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
