import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../shared/components/loading_indicator.dart';

class Import extends StatefulWidget {
  const Import({
    super.key,
    required this.path,
    required this.changeForceOverrideExisting,
  });

  final String path;
  final void Function({required bool forceOverrideExisting})
      changeForceOverrideExisting;

  @override
  State<Import> createState() => _ImportState();
}

class _ImportState extends State<Import> {
  late final _conflictStrategies =
      ImportConflictStrategy.values.toList(growable: false);
  late Future<List<String>> importableStores =
      FMTCRoot.external(pathToArchive: widget.path).listStores;

  ImportConflictStrategy selectedConflictStrategy = ImportConflictStrategy.skip;

  @override
  void didUpdateWidget(covariant Import oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      importableStores =
          FMTCRoot.external(pathToArchive: widget.path).listStores;
    }
  }

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
                onPressed: () => widget.changeForceOverrideExisting(
                  forceOverrideExisting: true,
                ),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Force Overwrite'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Importable Stores',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: FutureBuilder(
              future: importableStores,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 48),
                        Text(
                          "We couldn't open that archive.\nAre you sure it's "
                          'compatible with FMTC, and is unmodified?',
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const LoadingIndicator('Loading importable stores');
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_rounded, size: 48),
                        Text(
                          "There aren't any stores to import!\n"
                          'Check that you exported it correctly.',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final storeName = snapshot.data![index];

                    return ListTile(
                      title: Text(storeName),
                      subtitle: FutureBuilder(
                        future: FMTCStore(storeName).manage.ready,
                        builder: (context, snapshot) => Text(
                          switch (snapshot.data) {
                            null => 'Checking for conflicts...',
                            true => 'Conflicts with existing store',
                            false => 'No conflicts',
                          },
                        ),
                      ),
                      dense: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder(
                            future: FMTCStore(storeName).manage.ready,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 3,
                                  ),
                                );
                              }
                              if (snapshot.data!) {
                                return const Icon(Icons.merge_type_rounded);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.pending_outlined),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Conflict Strategy',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: DropdownButton(
              isExpanded: true,
              value: selectedConflictStrategy,
              items: _conflictStrategies
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Icon(
                            switch (e) {
                              ImportConflictStrategy.merge =>
                                Icons.merge_rounded,
                              ImportConflictStrategy.rename =>
                                Icons.edit_rounded,
                              ImportConflictStrategy.replace =>
                                Icons.save_as_rounded,
                              ImportConflictStrategy.skip =>
                                Icons.skip_next_rounded,
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            switch (e) {
                              ImportConflictStrategy.merge => 'Merge',
                              ImportConflictStrategy.rename => 'Rename',
                              ImportConflictStrategy.replace =>
                                'Replace/Overwrite',
                              ImportConflictStrategy.skip => 'Skip',
                            },
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (choice) =>
                  setState(() => selectedConflictStrategy = choice!),
            ),
          ),
        ],
      );
}
