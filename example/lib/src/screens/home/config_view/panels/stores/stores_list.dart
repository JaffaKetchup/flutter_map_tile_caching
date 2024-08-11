import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/exts/size_formatter.dart';
import 'components/column_headers_and_inheritable_settings.dart';
import 'components/export_stores_button.dart';
import 'components/new_store_button.dart';
import 'components/no_stores.dart';
import 'components/root_tile.dart';
import 'components/store_tile.dart';
import 'state/export_selection_provider.dart';

class StoresList extends StatefulWidget {
  const StoresList({
    super.key,
  });

  @override
  State<StoresList> createState() => _StoresListState();
}

class _StoresListState extends State<StoresList> {
  late Future<String> _rootLength;
  late Future<String> _rootSize;
  late Future<String> _rootRealSizeAdditional;

  late final storesStream =
      FMTCRoot.stats.watchStores(triggerImmediately: true).asyncMap(
    (_) async {
      _rootLength = FMTCRoot.stats.length.then((e) => e.toString());
      final size = FMTCRoot.stats.size;
      _rootSize = size.then((e) => (e * 1024).asReadableSize);
      _rootRealSizeAdditional = (FMTCRoot.stats.realSize, size)
          .wait
          .then((e) => '+${((e.$1 - e.$2) * 1024).asReadableSize}');

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
            itemCount: stores.length + 3,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const ColumnHeadersAndInheritableSettings();
              }
              if (index - 1 == stores.length) {
                return RootTile(
                  length: _rootLength,
                  size: _rootSize,
                  realSizeAdditional: _rootRealSizeAdditional,
                );
              }
              if (index - 2 == stores.length) {
                return Builder(
                  builder: (context) =>
                      context.select<ExportSelectionProvider, bool>(
                    (p) => p.selectedStores.isEmpty,
                  )
                          ? const NewStoreButton()
                          : const ExportStoresButton(),
                );
              }

              final store = stores.keys.elementAt(index - 1);
              final stats = stores.values.elementAt(index - 1).stats;
              final metadata = stores.values.elementAt(index - 1).metadata;
              final tileImage = stores.values.elementAt(index - 1).tileImage;

              return StoreTile(
                key: ValueKey(store),
                store: store,
                stats: stats,
                metadata: metadata,
                tileImage: tileImage,
              );
            },
            separatorBuilder: (context, index) => index - 2 == stores.length - 1
                ? const Divider()
                : index - 1 == stores.length - 1
                    ? const Divider(height: 8, indent: 12, endIndent: 12)
                    : const SizedBox.shrink(),
          );
        },
      );
}
