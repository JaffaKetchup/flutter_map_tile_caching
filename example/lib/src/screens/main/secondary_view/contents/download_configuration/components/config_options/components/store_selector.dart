import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../../../../../shared/misc/store_metadata_keys.dart';

class StoreSelector extends StatefulWidget {
  const StoreSelector({
    super.key,
    this.storeName,
    required this.onStoreNameSelected,
    this.enabled = true,
  });

  final String? storeName;
  final void Function(String?) onStoreNameSelected;
  final bool enabled;

  @override
  State<StoreSelector> createState() => _StoreSelectorState();
}

class _StoreSelectorState extends State<StoreSelector> {
  late final _storesToTemplatesStream = FMTCRoot.stats
      .watchStores(triggerImmediately: true)
      .asyncMap(
        (_) async => Map.fromEntries(
          await Future.wait(
            (await FMTCRoot.stats.storesAvailable).map(
              (s) async => MapEntry(
                s.storeName,
                await s.metadata.read.then(
                  (metadata) => metadata[StoreMetadataKeys.urlTemplate.key],
                ),
              ),
            ),
          ),
        ),
      )
      .distinct(mapEquals);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          child: StreamBuilder(
            stream: _storesToTemplatesStream,
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator.adaptive(),
                    SizedBox(width: 24),
                    Text('Loading stores...'),
                  ],
                );
              }

              return DropdownMenu(
                dropdownMenuEntries: _constructMenuEntries(snapshot),
                onSelected: widget.onStoreNameSelected,
                width: constraints.maxWidth,
                leadingIcon: const Icon(Icons.inventory),
                hintText: 'Select Store',
                initialSelection: widget.storeName,
                errorText: widget.storeName == null
                    ? 'Select a store to download tiles to'
                    : null,
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  helperMaxLines: 2,
                ),
                enabled: widget.enabled,
              );
            },
          ),
        ),
      );

  List<DropdownMenuEntry<String>> _constructMenuEntries(
    AsyncSnapshot<Map<String, String?>> snapshot,
  ) =>
      snapshot.data!.entries
          .whereNot((e) => e.value == null)
          .map(
            (e) => DropdownMenuEntry(
              value: e.key,
              label: e.key,
              labelWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key),
                  Text(
                    Uri.tryParse(e.value!)?.host ?? e.value!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          )
          .toList();
}
