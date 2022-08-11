import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/state/general_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    Key? key,
  }) : super(key: key);

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
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                keepAlive: true,
              ),
              nonRotatedChildren: [
                AttributionWidget.defaultWidget(
                  source: Uri.parse(urlTemplate).host,
                ),
              ],
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
                            ),
                          )
                      : NetworkNoRetryTileProvider(),
                  maxZoom: 20,
                  reset: provider.resetController.stream,
                  userAgentPackageName: 'dev.org.fmtc.example.app',
                  keepBuffer: 5,
                  backgroundColor: const Color(0xFFaad3df),
                  overrideTilesWhenUrlChanges: true,
                ),
              ],
            );
          },
        ),
      );
}
