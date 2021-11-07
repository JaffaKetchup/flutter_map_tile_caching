import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../state/general_provider.dart';

class MapView extends StatelessWidget {
  const MapView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) => FutureBuilder<CacheDirectory>(
        future: MapCachingManager.normalCache,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          final CacheDirectory parentDirectory = snapshot.data!;

          provider.newMapCachingManager = MapCachingManager(
            parentDirectory,
            'Default Store',
          );

          return FlutterMap(
            options: MapOptions(
              center: LatLng(51.524100927515704, -0.6701460534212902),
            ),
            layers: [
              TileLayerOptions(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                tileProvider: NonCachingNetworkTileProvider(),
                /*StorageCachingTileProvider(
                  parentDirectory: parentDirectory,
                  storeName: 'none',
                ),*/
                maxZoom: 20,
              ),
            ],
          );
        },
      ),
    );
  }
}
