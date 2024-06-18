import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../../shared/misc/store_metadata_keys.dart';
import '../../../../../../shared/state/general_provider.dart';
import '../../../../../store_editor/store_editor.dart';

class StoreTile extends StatelessWidget {
  const StoreTile({
    super.key,
    required this.store,
    required this.stats,
    required this.metadata,
    required this.tileImage,
  });

  final FMTCStore store;
  final Future<({int hits, int length, int misses, double size})> stats;
  final Future<Map<String, String>> metadata;
  final Future<Image?> tileImage;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Consumer<GeneralProvider>(
          builder: (context, provider, _) {
            final isSelected =
                provider.currentStores.contains(store.storeName) &&
                    provider.storesSelectionMode == false;

            return FutureBuilder(
              future: metadata,
              builder: (context, metadataSnapshot) {
                final matchesUrl = metadataSnapshot.data == null
                    ? null
                    : provider.urlTemplate ==
                        metadataSnapshot
                            .data![StoreMetadataKeys.urlTemplate.key];

                final inUse = provider.storesSelectionMode != null &&
                    (matchesUrl ?? false) &&
                    (provider.storesSelectionMode! || isSelected);

                return ListTile(
                  title: Text(store.storeName),
                  enabled: (provider.storesSelectionMode ?? true) ||
                      (matchesUrl ?? false),
                  subtitle: FutureBuilder(
                    future: stats,
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.data case final stats?) {
                        final statsPart =
                            '${stats.size.asReadableSize} | ${stats.length} tiles';

                        final usagePart = provider.storesSelectionMode == null
                            ? ''
                            : (matchesUrl ?? false)
                                ? (provider.storesSelectionMode ?? true) ||
                                        isSelected
                                    ? '\nIn use'
                                    : '\nNot in use'
                                : '\nSource mismatch';

                        return Text(statsPart + usagePart);
                      }

                      return const Text('Loading stats...\nLoading usage...');
                    },
                  ),
                  leading: SizedBox.square(
                    dimension: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FutureBuilder(
                            future: tileImage,
                            builder: (context, snapshot) {
                              if (snapshot.data case final data?) return data;
                              return const Icon(Icons.filter_none);
                            },
                          ),
                        ),
                        Center(
                          child: SizedBox.square(
                            dimension: 24,
                            child: AnimatedOpacity(
                              opacity: inUse ? 1 : 0,
                              duration: const Duration(milliseconds: 100),
                              curve: inUse ? Curves.easeIn : Curves.easeOut,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.of(context).pushNamed(
                          StoreEditorPopup.route,
                          arguments: store.storeName,
                        ),
                      ),
                    ],
                  ),
                  onTap: provider.storesSelectionMode == false
                      ? () {
                          if (isSelected) {
                            context
                                .read<GeneralProvider>()
                                .removeStore(store.storeName);
                          } else {
                            context
                                .read<GeneralProvider>()
                                .addStore(store.storeName);
                          }
                        }
                      : null,
                );
              },
            );
          },
        ),
      );
}
