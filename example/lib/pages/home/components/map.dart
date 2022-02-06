import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../state/general_provider.dart';

class MapView extends StatelessWidget {
  const MapView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final MapController controller;

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        final MapCachingManager mcm =
            MapCachingManager(provider.parentDirectory!, provider.storeName);
        final String? source =
            provider.persistent!.getString('${provider.storeName}: sourceURL');
        final String? cacheBehaviour = provider.persistent!
            .getString('${provider.storeName}: cacheBehaviour');
        final int? validDuration =
            provider.persistent!.getInt('${provider.storeName}: validDuration');
        final int? maxTiles =
            provider.persistent!.getInt('${provider.storeName}: maxTiles');

        return FlutterMap(
          mapController: controller,
          options: MapOptions(
            center: LatLng(51.524100927515704, -0.6701460534212902),
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: !provider.cachingEnabled || source == null
                  ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                  : source,
              tileProvider: provider.cachingEnabled
                  ? StorageCachingTileProvider.fromMapCachingManager(
                      mcm,
                      behavior: cacheBehaviour == 'cacheFirst'
                          ? CacheBehavior.cacheFirst
                          : cacheBehaviour == 'cacheOnly'
                              ? CacheBehavior.cacheOnly
                              : cacheBehaviour == 'onlineFirst'
                                  ? CacheBehavior.onlineFirst
                                  : CacheBehavior.cacheFirst,
                      cachedValidDuration: Duration(days: validDuration ?? 16),
                      maxStoreLength: maxTiles ?? 20000,
                    )
                  : const NonCachingNetworkTileProvider(),
              maxZoom: 20,
              reset: provider.resetController.stream,
            ),
          ],
        );
      },
    );
  }
}
