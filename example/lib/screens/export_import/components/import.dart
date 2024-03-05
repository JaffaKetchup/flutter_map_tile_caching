import 'package:flutter/material.dart';

class Import extends StatelessWidget {
  const Import({
    super.key,
    required this.changeForceOverrideExisting,
  });

  final void Function({required bool forceOverrideExisting})
      changeForceOverrideExisting;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Import Stores From Archive',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    changeForceOverrideExisting(forceOverrideExisting: true),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Force Overwrite'),
              ),
            ],
          ),
        ],
      );
}
