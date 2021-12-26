import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fmtc_example/state/bulk_download_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../state/general_provider.dart';
import 'region_mode.dart';

class MapView extends StatelessWidget {
  const MapView({
    Key? key,
    required this.controller,
    required this.mcm,
  }) : super(key: key);

  final MapController controller;
  final MapCachingManager mcm;

  final Distance dist = const Distance(roundResult: false);

  @override
  Widget build(BuildContext context) {
    return Consumer2<GeneralProvider, BulkDownloadProvider>(
      builder: (context, p, bdp, _) {
        final String? source =
            p.persistent!.getString('${mcm.storeName}: sourceURL') ??
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

        final LatLng center = bdp.centerAndEdge[0];
        final LatLng edge = bdp.centerAndEdge[1];

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
                  reset: p.resetController.stream,
                  tileBuilder: (_, child, __) => Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: child,
                  ),
                ),
                MarkerLayerOptions(
                  markers: [
                    _buildCrosshairMarker(center),
                    _buildCrosshairMarker(
                      bdp.mode == RegionMode.Circle
                          ? dist.offset(
                              center,
                              dist.distance(
                                center,
                                LatLng(edge.latitude, center.longitude),
                              ),
                              315,
                            )
                          : edge,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Marker _buildCrosshairMarker(LatLng point) {
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
  }
}
