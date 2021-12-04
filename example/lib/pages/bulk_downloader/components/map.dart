import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

class MapView extends StatefulWidget {
  const MapView({
    Key? key,
    required this.mcm,
    required this.chosenType,
    required this.rectLatLngs,
    required this.circleLatLngs,
    required this.onTap,
  }) : super(key: key);

  final MapCachingManager mcm;

  final String? chosenType;
  final List<List<double>> rectLatLngs;
  final List<List<double>> circleLatLngs;

  final void Function(LatLng)? onTap;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        final String? source = provider.persistent!
            .getString('${widget.mcm.storeName}: sourceURL');

        if (source == null ||
            source == 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png') {
          return Container(
            color: Colors.grey[300],
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  source == 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
                      ? Icons.warning
                      : Icons.error,
                  color: Colors.red,
                  size: 32,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Invalid Source URL',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You must configure a source URL that allows bulk downloading/\'pre-fetching\' under their ToS.\n\nAll other screens will use OpenStreetMaps by default, but OSM does not allow bulk downloading.\nYou must configure a valid URL in this store\'s editor.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      '/storeEditor',
                      arguments: widget.mcm,
                    );
                    setState(() {});
                  },
                  child: const Text('Edit Store'),
                ),
              ],
            ),
          );
        }

        return FlutterMap(
          options: MapOptions(
              center: LatLng(51.50781936891249, -0.12691235597072373),
              zoom: 10,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              onTap: (_, pos) {
                if (widget.onTap != null) widget.onTap!(pos);
              }),
          layers: [
            TileLayerOptions(
              urlTemplate: source,
              subdomains: ['a', 'b', 'c'],
              tileProvider: const NonCachingNetworkTileProvider(),
              maxZoom: 20,
              reset: provider.resetController.stream,
            ),
            widget.chosenType == 'rectangle'
                ? RectangleRegion(
                    LatLngBounds(
                      LatLng(
                        widget.rectLatLngs[0][0],
                        widget.rectLatLngs[0][1],
                      ),
                      LatLng(
                        widget.rectLatLngs[1][0],
                        widget.rectLatLngs[1][1],
                      ),
                    ),
                  ).toDrawable(Colors.green.withOpacity(0.5), Colors.black)
                : CircleRegion(
                    LatLng(
                      widget.circleLatLngs[0][0],
                      widget.circleLatLngs[0][1],
                    ),
                    widget.circleLatLngs[1][0],
                  ).toDrawable(Colors.green.withOpacity(0.5), Colors.black),
          ],
        );
      },
    );
  }
}
