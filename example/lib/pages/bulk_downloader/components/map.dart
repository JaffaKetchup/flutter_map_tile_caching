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
    required this.source,
  }) : super(key: key);

  final MapController controller;
  final MapCachingManager mcm;
  final String source;

  final Distance dist = const Distance(roundResult: false);

  @override
  Widget build(BuildContext context) {
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
              tileProvider: const NonCachingNetworkTileProvider(),
              maxZoom: 20,
              reset: context.read<GeneralProvider>().resetController.stream,
              tileBuilder: (_, child, __) => Container(
                decoration: BoxDecoration(border: Border.all()),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  /*Marker _buildCrosshairMarker(LatLng point) {
    return Marker(
      point: point,
      builder: (context) {
        return Stack(
          children: [
            Center(
              child: Container(
                color: Colors.black,
                height: 1,
                width: 10,
              ),
            ),
            Center(
              child: Container(
                color: Colors.black,
                height: 10,
                width: 1,
              ),
            )
          ],
        );
      },
    );
  }*/
}
