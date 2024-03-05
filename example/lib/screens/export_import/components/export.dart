import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../shared/components/loading_indicator.dart';

class Export extends StatefulWidget {
  const Export({
    super.key,
    required this.selectedStores,
  });

  final Set<String> selectedStores;

  @override
  State<Export> createState() => _ExportState();
}

class _ExportState extends State<Export> {
  late final stores = FMTCRoot.stats.storesAvailable;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Stores To Archive',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder(
              future: stores,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingIndicator('Loading available stores');
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_rounded, size: 48),
                        Text(
                          "There aren't any stores to export!",
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                final availableStores =
                    snapshot.data!.map((e) => e.storeName).toList();

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    availableStores.length,
                    (i) {
                      final storeName = availableStores[i];
                      return ChoiceChip(
                        label: Text(storeName),
                        selected: widget.selectedStores.contains(storeName),
                        onSelected: (selected) {
                          if (selected) {
                            widget.selectedStores.add(storeName);
                          } else {
                            widget.selectedStores.remove(storeName);
                          }
                          setState(() {});
                        },
                      );
                    },
                    growable: false,
                  ),
                );
              },
            ),
          ),
        ],
      );
}
