import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../shared/components/build_attribution.dart';
import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/misc/region_selection_method.dart';
import '../../../../shared/misc/region_type.dart';
import '../../../../shared/state/general_provider.dart';
import '../../../configure_download/configure_download.dart';
import 'components/crosshairs.dart';
import 'components/custom_polygon_snapping_indicator.dart';
import 'components/region_shape.dart';
import 'components/side_panel/parent.dart';
import 'components/usage_instructions.dart';
import 'state/region_selection_provider.dart';

class RegionSelectionPage extends StatefulWidget {
  const RegionSelectionPage({super.key});

  @override
  State<RegionSelectionPage> createState() => _RegionSelectionPageState();
}

class _RegionSelectionPageState extends State<RegionSelectionPage> {
  final mapController = MapController();

  late final mapOptions = MapOptions(
    initialCenter: const LatLng(51.509364, -0.128928),
    initialZoom: 11,
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all &
          ~InteractiveFlag.rotate &
          ~InteractiveFlag.doubleTapZoom,
      scrollWheelVelocity: 0.002,
    ),
    keepAlive: true,
    backgroundColor: const Color(0xFFaad3df),
    onTap: (_, __) {
      final provider = context.read<RegionSelectionProvider>();

      if (provider.isCustomPolygonComplete) return;

      final List<LatLng> coords;
      if (provider.customPolygonSnap &&
          provider.regionType == RegionType.customPolygon) {
        coords = provider.addCoordinate(provider.coordinates.first);
        provider.customPolygonSnap = false;
      } else {
        coords = provider.addCoordinate(provider.currentNewPointPos);
      }

      if (coords.length < 2) return;

      switch (provider.regionType) {
        case RegionType.square:
          if (coords.length == 2) {
            provider.region = RectangleRegion(LatLngBounds.fromPoints(coords));
            break;
          }
          provider
            ..clearCoordinates()
            ..addCoordinate(provider.currentNewPointPos);

          break;
        case RegionType.circle:
          if (coords.length == 2) {
            provider.region = CircleRegion(
              coords[0],
              const Distance(roundResult: false)
                      .distance(coords[0], coords[1]) /
                  1000,
            );
            break;
          }
          provider
            ..clearCoordinates()
            ..addCoordinate(provider.currentNewPointPos);

          break;
        case RegionType.line:
          provider.region = LineRegion(coords, provider.lineRadius);
          break;
        case RegionType.customPolygon:
          if (!provider.isCustomPolygonComplete) break;
          provider.region = CustomPolygonRegion(coords);
          break;
      }
    },
    onSecondaryTap: (_, __) =>
        context.read<RegionSelectionProvider>().removeLastCoordinate(),
    onLongPress: (_, __) =>
        context.read<RegionSelectionProvider>().removeLastCoordinate(),
    onPointerHover: (evt, point) {
      final provider = context.read<RegionSelectionProvider>();

      if (provider.regionSelectionMethod == RegionSelectionMethod.usePointer) {
        provider.currentNewPointPos = point;

        if (provider.regionType == RegionType.customPolygon) {
          final coords = provider.coordinates;
          if (coords.length > 1) {
            final newPointPos = mapController.camera
                .latLngToScreenPoint(coords.first)
                .toOffset();
            provider.customPolygonSnap = coords.first != coords.last &&
                sqrt(
                      pow(newPointPos.dx - evt.localPosition.dx, 2) +
                          pow(newPointPos.dy - evt.localPosition.dy, 2),
                    ) <
                    15;
          }
        }
      }
    },
    onPositionChanged: (position, _) {
      final provider = context.read<RegionSelectionProvider>();

      if (provider.regionSelectionMethod ==
          RegionSelectionMethod.useMapCenter) {
        provider.currentNewPointPos = position.center!;

        if (provider.regionType == RegionType.customPolygon) {
          final coords = provider.coordinates;
          if (coords.length > 1) {
            final newPointPos = mapController.camera
                .latLngToScreenPoint(coords.first)
                .toOffset();
            final centerPos = mapController.camera
                .latLngToScreenPoint(provider.currentNewPointPos)
                .toOffset();
            provider.customPolygonSnap = coords.first != coords.last &&
                sqrt(
                      pow(newPointPos.dx - centerPos.dx, 2) +
                          pow(newPointPos.dy - centerPos.dy, 2),
                    ) <
                    30;
          }
        }
      }
    },
  );

  bool keyboardHandler(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final provider = context.read<RegionSelectionProvider>();

    if (provider.region != null &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      pushToConfigureDownload();
    } else if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      provider.clearCoordinates();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      provider.removeLastCoordinate();
    } else if (provider.regionType != RegionType.square &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      provider
        ..regionType = RegionType.square
        ..clearCoordinates();
    } else if (provider.regionType != RegionType.circle &&
        event.logicalKey == LogicalKeyboardKey.keyX) {
      provider
        ..regionType = RegionType.circle
        ..clearCoordinates();
    } else if (provider.regionType != RegionType.line &&
        event.logicalKey == LogicalKeyboardKey.keyC) {
      provider
        ..regionType = RegionType.line
        ..clearCoordinates();
    } else if (provider.regionType != RegionType.customPolygon &&
        event.logicalKey == LogicalKeyboardKey.keyV) {
      provider
        ..regionType = RegionType.customPolygon
        ..clearCoordinates();
    }

    return false;
  }

  void pushToConfigureDownload() {
    final provider = context.read<RegionSelectionProvider>();
    ServicesBinding.instance.keyboard.removeHandler(keyboardHandler);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ConfigureDownloadPopup(
              region: provider.region!,
              minZoom: provider.minZoom,
              maxZoom: provider.maxZoom,
            ),
            fullscreenDialog: true,
          ),
        )
        .then(
          (_) => ServicesBinding.instance.keyboard.addHandler(keyboardHandler),
        );
  }

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(keyboardHandler);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(keyboardHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Selector<GeneralProvider, String?>(
              selector: (context, provider) => provider.currentStore,
              builder: (context, currentStore, _) =>
                  FutureBuilder<Map<String, String>?>(
                future: currentStore == null
                    ? Future.value()
                    : FMTC.instance(currentStore).metadata.read,
                builder: (context, metadata) {
                  if (currentStore != null && metadata.data == null) {
                    return const LoadingIndicator('Preparing Map');
                  }

                  final urlTemplate = metadata.data?['sourceURL'] ??
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

                  return MouseRegion(
                    opaque: false,
                    cursor: context.select<RegionSelectionProvider,
                                RegionSelectionMethod>(
                              (p) => p.regionSelectionMethod,
                            ) ==
                            RegionSelectionMethod.useMapCenter
                        ? MouseCursor.defer
                        : context.select<RegionSelectionProvider, bool>(
                            (p) => p.customPolygonSnap,
                          )
                            ? SystemMouseCursors.none
                            : SystemMouseCursors.precise,
                    child: FlutterMap(
                      mapController: mapController,
                      options: mapOptions,
                      children: [
                        TileLayer(
                          urlTemplate: urlTemplate,
                          userAgentPackageName: 'dev.jaffaketchup.fmtc.demo',
                          maxNativeZoom: 20,
                          tileBuilder: (context, widget, tile) =>
                              FutureBuilder<bool?>(
                            future: currentStore == null
                                ? Future.value()
                                : FMTC
                                    .instance(currentStore)
                                    .getTileProvider()
                                    .checkTileCached(
                                      coords: tile.coordinates,
                                      options:
                                          TileLayer(urlTemplate: urlTemplate),
                                    ),
                            builder: (context, snapshot) => DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                color: (snapshot.data ?? false)
                                    ? Colors.deepOrange.withOpacity(1 / 3)
                                    : Colors.transparent,
                              ),
                              child: widget,
                            ),
                          ),
                        ),
                        const RegionShape(),
                        const CustomPolygonSnappingIndicator(),
                        StandardAttribution(urlTemplate: urlTemplate),
                      ],
                    ),
                  );
                },
              ),
            ),
            SidePanel(
              constraints: constraints,
              pushToConfigureDownload: pushToConfigureDownload,
            ),
            if (context.select<RegionSelectionProvider, RegionSelectionMethod>(
                      (p) => p.regionSelectionMethod,
                    ) ==
                    RegionSelectionMethod.useMapCenter &&
                !context.select<RegionSelectionProvider, bool>(
                  (p) => p.customPolygonSnap,
                ))
              const Center(child: Crosshairs()),
            UsageInstructions(constraints: constraints),
          ],
        ),
      );
}
