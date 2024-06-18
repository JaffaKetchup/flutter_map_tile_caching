import 'package:flutter/material.dart';

import '../../../../../store_editor/store_editor.dart';

class NewStoreButton extends StatelessWidget {
  const NewStoreButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: FilledButton.tonalIcon(
                    label: const Text('Create new store'),
                    icon: const Icon(Icons.create_new_folder),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(StoreEditorPopup.route),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: const Icon(Icons.file_open),
                tooltip: 'Import store',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
}
