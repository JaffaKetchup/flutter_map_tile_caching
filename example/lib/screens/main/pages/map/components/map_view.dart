import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/general_provider.dart';

class MapView extends StatefulWidget {
  const MapView({
    Key? key,
    required MapController mapController,
  })  : _mapController = mapController,
        super(key: key);

  final MapController _mapController;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) => Consumer<GeneralProvider>(
        builder: (context, provider, _) => FlutterMap(
          mapController: widget._mapController,
          options: MapOptions(
            center: LatLng(51.509364, -0.128928),
            zoom: 9.2,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: //!provider.cachingEnabled || source == null ?
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //: source,
              tileProvider: provider.currentStore != null
                  ? FMTC.instance(provider.currentStore!).getTileProvider(
                        FMTCTileProviderSettings(
                            /*behavior: cacheBehaviour == 'cacheFirst'
                            ? CacheBehavior.cacheFirst
                            : cacheBehaviour == 'cacheOnly'
                                ? CacheBehavior.cacheOnly
                                : cacheBehaviour == 'onlineFirst'
                                    ? CacheBehavior.onlineFirst
                                    : CacheBehavior.cacheFirst,
                        cachedValidDuration: Duration(days: validDuration ?? 16),
                        maxStoreLength: maxTiles ?? 20000,*/
                            ),
                      )
                  : const NonCachingNetworkTileProvider(),
              maxZoom: 20,
              reset: provider.resetController.stream.map((_) => null),
            ),
          ],
        ),
      );
}
