import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/state/general_provider.dart';
import 'build_attribution.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) => Consumer<GeneralProvider>(
        builder: (context, provider, _) => FutureBuilder<Map<String, String>?>(
          future: provider.currentStore == null
              ? Future.sync(() => {})
              : FMTC.instance(provider.currentStore!).metadata.readAsync,
          builder: (context, metadata) {
            if (!metadata.hasData ||
                metadata.data == null ||
                (provider.currentStore != null && metadata.data!.isEmpty)) {
              return const LoadingIndicator(
                message:
                    'Loading Settings...\n\nSeeing this screen for a long time?\nThere may be a misconfiguration of the\nstore. Try disabling caching and deleting\n faulty stores.',
              );
            }

            final String urlTemplate =
                provider.currentStore != null && metadata.data != null
                    ? metadata.data!['sourceURL']!
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

            return FlutterMap(
              options: MapOptions(
                center: LatLng(51.509364, -0.128928),
                zoom: 9.2,
                maxZoom: 22,
                maxBounds: LatLngBounds.fromPoints([
                  LatLng(51.50440309992153, -0.7140577160848564),
                  LatLng(51.50359743451854, -0.5780629452415917),
                  LatLng(51.536279957688045, -0.5727737156917649),
                  LatLng(-51.53318462807709, -0.7227703206129361),
                ]),
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                scrollWheelVelocity: 0.002,
                keepAlive: true,
              ),
              nonRotatedChildren: buildStdAttribution(urlTemplate),
              children: [
                TileLayer(
                  urlTemplate: urlTemplate,
                  tileProvider: provider.currentStore != null
                      ? FMTC.instance(provider.currentStore!).getTileProvider(
                            FMTCTileProviderSettings(
                              behavior: CacheBehavior.values
                                  .byName(metadata.data!['behaviour']!),
                              cachedValidDuration: int.parse(
                                        metadata.data!['validDuration']!,
                                      ) ==
                                      0
                                  ? Duration.zero
                                  : Duration(
                                      days: int.parse(
                                        metadata.data!['validDuration']!,
                                      ),
                                    ),
                              maxStoreLength: int.parse(
                                metadata.data!['maxLength']!,
                              ),
                            ),
                          )
                      : NetworkNoRetryTileProvider(),
                  maxZoom: 22,
                  userAgentPackageName: 'dev.org.fmtc.example.app',
                  panBuffer: 3,
                  backgroundColor: const Color(0xFFaad3df),
                ),
              ],
            );
          },
        ),
      );
}
