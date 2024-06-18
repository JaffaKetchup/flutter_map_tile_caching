import 'package:flutter/material.dart';

import '../../../../../store_editor/store_editor.dart';

class NoStores extends StatelessWidget {
  const NoStores({
    super.key,
  });

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
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(StoreEditorPopup.route),
                    icon: const Icon(Icons.create_new_folder),
                    label: const Text('Create new store'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_open),
                    label: const Text('Import a store'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
