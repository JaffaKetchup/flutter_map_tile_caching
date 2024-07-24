import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'new_store_button.dart';
import 'no_stores.dart';
import 'store_tile.dart';

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
      return {
        for (final store in stores)
          store: (
            stats: store.stats.all,
            metadata: store.metadata.read,
            tileImage: store.stats.tileImage(size: 51.2, fit: BoxFit.cover),
          ),
      };
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

          if (stores.isEmpty) return const NoStores();

          return SliverList.separated(
            itemCount: stores.length + 1,
            itemBuilder: (context, index) {
              if (index == stores.length) return const NewStoreButton();

              final store = stores.keys.elementAt(index);
              final stats = stores.values.elementAt(index).stats;
              final metadata = stores.values.elementAt(index).metadata;
              final tileImage = stores.values.elementAt(index).tileImage;

              return StoreTile(
                store: store,
                stats: stats,
                metadata: metadata,
                tileImage: tileImage,
              );
            },
            separatorBuilder: (context, index) => index == stores.length - 1
                ? const Divider()
                : const SizedBox.shrink(),
          );
        },
      );
}
