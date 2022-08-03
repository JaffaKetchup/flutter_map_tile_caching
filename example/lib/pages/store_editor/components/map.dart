import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

class MapView extends StatelessWidget {
  const MapView({
    Key? key,
    required this.source,
  }) : super(key: key);

  final String source;

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) => FlutterMap(
        options: MapOptions(
          center: LatLng(51.50781936891249, -0.12691235597072373),
        ),
        children: [
          TileLayerWidget(options: TileLayerOptions(
            urlTemplate: source,
            subdomains: ['a', 'b', 'c'],
            tileProvider: NonCachingNetworkTileProvider(),
            maxZoom: 20,
            reset: provider.resetController.stream,
          )),
        ],
      ),
    );
  }
}
