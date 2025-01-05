import 'package:flutter/material.dart';

import '../../../../../../../import/import.dart';
import '../../../../../../../store_editor/store_editor.dart';
import 'export_stores/example_app_limitations_text.dart';

class NewStoreButton extends StatefulWidget {
  const NewStoreButton({super.key});

  @override
  State<NewStoreButton> createState() => _NewStoreButtonState();
}

class _NewStoreButtonState extends State<NewStoreButton> {
  bool _showingImportExportButtons = false;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AnimatedCrossFade(
                    crossFadeState: _showingImportExportButtons
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                    firstCurve: Curves.easeInOut,
                    secondCurve: Curves.easeInOut,
                    sizeCurve: Curves.easeInOut,
                    firstChild: SizedBox(
                      height: 38,
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        label: const Text('Create new store'),
                        icon: const Icon(Icons.create_new_folder),
                        onPressed: () => Navigator.of(context)
                            .pushNamed(StoreEditorPopup.route),
                      ),
                    ),
                    secondChild: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () => ImportPopup.start(context),
                              icon: const Icon(Icons.file_open),
                              label: const Text('Import'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.send_and_archive),
                              label: const Text('Export'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedCrossFade(
                  crossFadeState: _showingImportExportButtons
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                  firstCurve: Curves.easeInOut,
                  secondCurve: Curves.easeInOut,
                  sizeCurve: Curves.easeInOut,
                  firstChild: IconButton.outlined(
                    icon: const Icon(Icons.import_export),
                    tooltip: 'Import/Export',
                    onPressed: () =>
                        setState(() => _showingImportExportButtons = true),
                  ),
                  secondChild: IconButton(
                    onPressed: () =>
                        setState(() => _showingImportExportButtons = false),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              exampleAppLimitationsText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
}
