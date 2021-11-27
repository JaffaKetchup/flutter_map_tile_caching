import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

class MapView extends StatelessWidget {
  const MapView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        final String? source =
            provider.persistent!.getString('${provider.storeName}: sourceURL');

        return FlutterMap(
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
            ),
          ],
        );
      },
    );
  }
}
