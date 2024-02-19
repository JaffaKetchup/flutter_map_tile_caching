import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/components/build_attribution.dart';
import '../../../../../shared/components/loading_indicator.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../downloading/state/downloading_provider.dart';
import '../../region_selection/components/region_shape.dart';
import '../state/map_provider.dart';
import 'empty_tile_provider.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) => Selector<GeneralProvider, String?>(
        selector: (context, provider) => provider.currentStore,
        builder: (context, currentStore, _) =>
            FutureBuilder<Map<String, String>?>(
          future: currentStore == null
              ? Future.sync(() => {})
              : FMTCStore(currentStore).metadata.read,
          builder: (context, metadata) {
            if (!metadata.hasData ||
                metadata.data == null ||
                (currentStore != null && metadata.data!.isEmpty)) {
              return const LoadingIndicator('Preparing Map');
            }

            final urlTemplate = currentStore != null && metadata.data != null
                ? metadata.data!['sourceURL']!
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

            return FlutterMap(
              mapController: Provider.of<MapProvider>(context).mapController,
              options: const MapOptions(
                initialCenter: LatLng(51.509364, -0.128928),
                initialZoom: 12,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  scrollWheelVelocity: 0.002,
                ),
                keepAlive: true,
                backgroundColor: Color(0xFFaad3df),
              ),
              children: [
                if (context.select<DownloadingProvider,
                        StreamSubscription<DownloadProgress>?>(
                      (provider) => provider.tilesPreviewStreamSub,
                    ) ==
                    null)
                  TileLayer(
                    urlTemplate: urlTemplate,
                    userAgentPackageName: 'dev.jaffaketchup.fmtc.demo',
                    maxNativeZoom: 20,
                    panBuffer: 5,
                    tileProvider: currentStore != null
                        ? FMTCStore(currentStore).getTileProvider(
                            settings: FMTCTileProviderSettings(
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
                        : NetworkTileProvider(),
                  )
                else ...[
                  const SizedBox.expand(
                    child: ColoredBox(color: Colors.grey),
                  ),
                  TileLayer(
                    tileBuilder: (context, widget, tile) {
                      final bytes = context
                          .read<DownloadingProvider>()
                          .tilesPreview[tile.coordinates];
                      if (bytes == null) return const SizedBox.shrink();
                      return Image.memory(bytes);
                    },
                    tileProvider: EmptyTileProvider(),
                  ),
                  const RegionShape(),
                ],
                StandardAttribution(urlTemplate: urlTemplate),
              ],
            );
          },
        ),
      );
}
