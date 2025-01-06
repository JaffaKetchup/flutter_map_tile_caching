import 'package:flutter/material.dart';

import '../../../../../../../import/import.dart';
import '../../../../../../../store_editor/store_editor.dart';
import 'example_app_limitations_text.dart';

class NoStores extends StatelessWidget {
  const NoStores({
    super.key,
    required this.newStoreName,
  });

  final void Function(String) newStoreName;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_off, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Homes for tiles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tiles belong to one or more stores, but it looks like you '
                  "don't have one yet!\nCreate or import one to get started.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context)
                          .pushNamed(StoreEditorPopup.route);
                      if (result is String) newStoreName(result);
                    },
                    icon: const Icon(Icons.create_new_folder),
                    label: const Text('Create new store'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ImportPopup.start(context),
                    icon: const Icon(Icons.file_open),
                    label: const Text('Import a store'),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  exampleAppLimitationsText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      );
}
