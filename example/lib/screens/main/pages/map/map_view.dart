import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/state/general_provider.dart';
import '../../../../shared/state/map_provider.dart';
import 'build_attribution.dart';

enum UserLocationFollowState {
  off,
  standard,
  navigation,
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

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
                    'Loading Map...\n\nSeeing this screen for a long time?\nThere may be a misconfiguration of the\nstore. Try disabling caching and deleting\n faulty stores.',
              );
            }

            final String urlTemplate =
                provider.currentStore != null && metadata.data != null
                    ? metadata.data!['sourceURL']!
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

            return FlutterMap(
              mapController: Provider.of<MapProvider>(context).mapController,
              options: MapOptions(
                initialCenter: const LatLng(51.509364, -0.128928),
                initialZoom: 16,
                maxZoom: 22,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds.fromPoints([
                    const LatLng(-90, 180),
                    const LatLng(90, 180),
                    const LatLng(90, -180),
                    const LatLng(-90, -180),
                  ]),
                ),
                interactionOptions: const InteractionOptions(
                  // flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  scrollWheelVelocity: 0.002,
                ),
                keepAlive: true,
                onPointerDown: (_, __) =>
                    Provider.of<MapProvider>(context, listen: false)
                        .followState = UserLocationFollowState.off,
              ),
              nonRotatedChildren: buildStdAttribution(
                urlTemplate,
                alignment: AttributionAlignment.bottomLeft,
              ),
              children: [
                TileLayer(
                  urlTemplate: urlTemplate,
                  tileProvider: provider.currentStore != null
                      ? FMTC.instance(provider.currentStore!).getTileProvider(
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
                  maxZoom: 22,
                  userAgentPackageName: 'dev.jaffaketchup.fmtc.demo',
                  panBuffer: 3,
                  backgroundColor: const Color(0xFFaad3df),
                ),
                Consumer<MapProvider>(
                  builder: (context, mapProvider, _) => CurrentLocationLayer(
                    followCurrentLocationStream:
                        mapProvider.trackLocationStream,
                    turnHeadingUpLocationStream: mapProvider.trackHeadingStream,
                    followOnLocationUpdate:
                        mapProvider.followState != UserLocationFollowState.off
                            ? FollowOnLocationUpdate.always
                            : FollowOnLocationUpdate.never,
                    turnOnHeadingUpdate: mapProvider.followState ==
                            UserLocationFollowState.navigation
                        ? TurnOnHeadingUpdate.always
                        : TurnOnHeadingUpdate.never,
                    style: const LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        child: Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      markerSize: Size(30, 30),
                      markerDirection: MarkerDirection.heading,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
