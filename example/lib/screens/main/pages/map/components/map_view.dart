import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/components/loading_indicator.dart';
import '../../../../../shared/state/general_provider.dart';

class MapView extends StatefulWidget {
  const MapView({
    Key? key,
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
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
              ),
              layers: [
                TileLayerOptions(
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
                      : const NonCachingNetworkTileProvider(),
                  maxZoom: 20,
                  reset: provider.resetController.stream,
                  keepBuffer: 5,
                  backgroundColor: const Color(0xFFaad3df),
                  overrideTilesWhenUrlChanges: true,
                ),
              ],
              nonRotatedChildren: [
                AttributionWidget.defaultWidget(
                  source: Uri.parse(urlTemplate).host,
                ),
              ],
            );
          },
        ),
      );
}
