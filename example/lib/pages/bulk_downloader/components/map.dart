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
    required this.mcm,
  }) : super(key: key);

  final MapController controller;
  final MapCachingManager mcm;

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        final String? source =
            provider.persistent!.getString('${mcm.storeName}: sourceURL');

        return FutureBuilder<void>(
          future: controller.onReady,
          builder: (context, _) {
            return FlutterMap(
              mapController: controller,
              options: MapOptions(
                center: LatLng(51.50781936891249, -0.12691235597072373),
                zoom: 10,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              layers: [
                TileLayerOptions(
                  urlTemplate: source,
                  subdomains: ['a', 'b', 'c'],
                  tileProvider: const NonCachingNetworkTileProvider(),
                  maxZoom: 20,
                  reset: provider.resetController.stream,
                  tileBuilder: (_, child, __) => Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
