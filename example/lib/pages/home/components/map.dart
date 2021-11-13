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
        return FlutterMap(
          mapController: controller,
          options: MapOptions(
            center: LatLng(51.524100927515704, -0.6701460534212902),
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
              tileProvider: provider.cachingEnabled
                  ? StorageCachingTileProvider(
                      parentDirectory:
                          provider.currentMapCachingManager.parentDirectory,
                      storeName: provider.currentMapCachingManager.storeName,
                    )
                  : const NonCachingNetworkTileProvider(),
              maxZoom: 20,
              reset: provider.resetController.stream,
            ),
            PolylineLayerOptions(
              polylines: [
                Polyline(
                  points: [
                    LatLng(51.524100927515704, -0.6701460534212902),
                    LatLng(51.5200421491665, -0.654524867958212),
                    LatLng(51.51160300471206, -0.6633654281532659),
                  ],
                  strokeWidth: 50,
                  color: Colors.black45,
                  borderColor: Colors.black,
                  borderStrokeWidth: 5,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
