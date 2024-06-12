import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../shared/misc/exts/size_formatter.dart';
import '../../../../shared/state/general_provider.dart';

class StoresList extends StatefulWidget {
  const StoresList({
    super.key,
  });

  @override
  State<StoresList> createState() => _StoresListState();
}

class _StoresListState extends State<StoresList> {
  late final storesStream =
      FMTCRoot.stats.watchStores(triggerImmediately: true).asyncMap(
    (_) async {
      final stores = await FMTCRoot.stats.storesAvailable;
      return HashMap.fromEntries(
        stores.map(
          (store) => MapEntry(
            store,
            (
              stats: store.stats.all,
              metadata: store.metadata.read,
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: storesStream,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            );
          }

          final stores = snapshot.data!;

          if (stores.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                        'Tiles belong to one or more stores, so create a store to '
                        'get started',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.create_new_folder),
                        label: const Text('Create new store'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverList.builder(
            itemCount: stores.length + 1,
            itemBuilder: (context, index) {
              if (index == stores.length) {
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: const Text('Create new store'),
                    onTap: () {},
                    leading: const SizedBox.square(
                      dimension: 56,
                      child: Center(child: Icon(Icons.create_new_folder)),
                    ),
                  ),
                );
              }

              final store = stores.keys.elementAt(index);
              final stats = stores.values.elementAt(index).stats;
              //final metadata = stores.values.elementAt(index).metadata;

              return Material(
                color: Colors.transparent,
                child: Consumer<GeneralProvider>(
                  builder: (context, provider, _) {
                    final isSelected =
                        provider.currentStores.contains(store.storeName) &&
                            provider.storesSelectionMode == false;

                    return ListTile(
                      title: Text(store.storeName),
                      subtitle: FutureBuilder(
                        future: stats,
                        builder: (context, snapshot) {
                          if (snapshot.data == null) {
                            return const Text('Loading stats...');
                          }

                          return Text(
                            '${snapshot.data!.size.asReadableSize} | ${snapshot.data!.length} tiles',
                          );
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
                                future: store.stats.tileImage(size: 56),
                                builder: (context, snapshot) {
                                  if (snapshot.data != null) {
                                    return snapshot.data!;
                                  }
                                  return const ColoredBox(color: Colors.white);
                                },
                              ),
                            ),
                            Center(
                              child: SizedBox.square(
                                dimension: 24,
                                child: AnimatedOpacity(
                                  opacity: isSelected ? 1 : 0,
                                  duration: const Duration(milliseconds: 100),
                                  curve: isSelected
                                      ? Curves.easeIn
                                      : Curves.easeOut,
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
                            onPressed: () {},
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
                ),
              );
            },
          );
        },
      );
}
