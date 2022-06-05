import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../../shared/components/loading_indicator.dart';
import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../../../../shared/vars/region_mode.dart';
import 'crosshairs.dart';

class MapView extends StatefulWidget {
  const MapView({
    Key? key,
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final _mapKey = GlobalKey<State<StatefulWidget>>();

  late final MapController _mapController;
  late final StreamSubscription _polygonVisualizerStream;
  late final StreamSubscription _tileCounterTriggerStream;

  LatLng? _pointTL;
  LatLng? _pointBR;

  LatLng? _center;
  double? _radius;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _polygonVisualizerStream =
        _mapController.mapEventStream.listen((_) => _updatePointLatLng());
    _tileCounterTriggerStream = _mapController.mapEventStream
        .debounce(const Duration(milliseconds: 500))
        .listen((_) => _countTiles());

    Future.delayed(Duration.zero, () async {
      await _mapController.onReady;

      if (!mounted) return;
      _updatePointLatLng();
      unawaited(_countTiles());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _polygonVisualizerStream.cancel();
    _tileCounterTriggerStream.cancel();
  }

  @override
  Widget build(BuildContext context) =>
      Consumer2<GeneralProvider, DownloadProvider>(
        key: _mapKey,
        builder: (context, generalProvider, downloadProvider, _) =>
            LayoutBuilder(
          builder: (context, constraints) =>
              FutureBuilder<Map<String, String>?>(
            future: generalProvider.currentStore == null
                ? Future.sync(() => {})
                : FMTC
                    .instance(generalProvider.currentStore!)
                    .metadata
                    .readAsync,
            builder: (context, metadata) {
              if (!metadata.hasData ||
                  metadata.data == null ||
                  (generalProvider.currentStore != null &&
                      (metadata.data ?? {}).isEmpty)) {
                return const LoadingIndicator(
                  message:
                      'Loading Settings...\n\nSeeing this screen for a long time?\nThere may be a misconfiguration of the\nstore. Try disabling caching and deleting\n faulty stores.',
                );
              }
              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(51.509364, -0.128928),
                      zoom: 9.2,
                      interactiveFlags:
                          InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    children: [
                      TileLayerWidget(
                        options: TileLayerOptions(
                          urlTemplate: generalProvider.currentStore != null &&
                                  metadata.data != null
                              ? metadata.data!['sourceURL']!
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          maxZoom: 20,
                          reset: generalProvider.resetController.stream,
                          keepBuffer: 5,
                          backgroundColor: const Color(0xFFaad3df),
                        ),
                      ),
                      if (_pointTL != null &&
                          _pointBR !=
                              null /*&&
                          downloadProvider.regionMode != RegionMode.circle*/
                      )
                        PolygonLayerWidget(
                          options: PolygonLayerOptions(
                            polygons: [
                              Polygon(
                                points: RectangleRegion(
                                  LatLngBounds(_pointTL, _pointBR),
                                ).toList(),
                                isFilled: true,
                                color: Colors.green.withOpacity(0.5),
                              )
                            ],
                          ),
                        )
                      else if (_center != null &&
                          _radius != null &&
                          downloadProvider.regionMode == RegionMode.circle)
                        PolygonLayerWidget(
                          options: PolygonLayerOptions(
                            polygons: [
                              Polygon(
                                points: CircleRegion(
                                  _center!,
                                  _radius!,
                                ).toList(),
                                isFilled: true,
                                color: Colors.green.withOpacity(0.5),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (downloadProvider.regionMode != RegionMode.circle) ...[
                    Positioned(
                      top: downloadProvider.regionMode == RegionMode.square
                          ? constraints.maxHeight - (constraints.maxWidth + 56)
                          : downloadProvider.regionMode ==
                                  RegionMode.rectangleHorizontal
                              ? constraints.maxHeight / 3
                              : 15,
                      left: 15,
                      child: const Crosshairs(),
                    ),
                    Positioned(
                      bottom: downloadProvider.regionMode == RegionMode.square
                          ? constraints.maxHeight - (constraints.maxWidth + 56)
                          : downloadProvider.regionMode ==
                                  RegionMode.rectangleHorizontal
                              ? constraints.maxHeight / 3
                              : 15,
                      right: 15,
                      child: const Crosshairs(),
                    ),
                  ] else ...[
                    Positioned(
                      top: (constraints.maxHeight / 2) - 10,
                      left: (constraints.maxWidth / 2) - 10,
                      child: const Crosshairs(),
                    ),
                    Positioned(
                      top: constraints.maxHeight - (constraints.maxWidth + 56),
                      left: (constraints.maxWidth / 2) - 10,
                      child: const Crosshairs(),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      );

  void _updatePointLatLng() {
    final DownloadProvider downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    final Size mapSize = _mapKey.currentContext!.size!;

    switch (downloadProvider.regionMode) {
      case RegionMode.square:
        setState(
          () {
            _pointTL = _mapController
                .pointToLatLng(CustomPoint(24, mapSize.width + 48));
            _pointBR = _mapController.pointToLatLng(
              CustomPoint(
                mapSize.width - 24,
                mapSize.height - mapSize.width - 48,
              ),
            );
          },
        );
        break;
      case RegionMode.rectangleVertical:
        setState(
          () {
            _pointTL = _mapController.pointToLatLng(const CustomPoint(24, 24));
            _pointBR = _mapController.pointToLatLng(
              CustomPoint(
                mapSize.width - 24,
                mapSize.height - 24,
              ),
            );
          },
        );
        break;
      case RegionMode.rectangleHorizontal:
        setState(
          () {
            _pointTL = _mapController
                .pointToLatLng(CustomPoint(24, mapSize.height / 3 + 10));
            _pointBR = _mapController.pointToLatLng(
              CustomPoint(
                mapSize.width - 24,
                mapSize.height - mapSize.height / 3 - 10,
              ),
            );
          },
        );
        break;
      case RegionMode.circle:
        setState(
          () {
            _center = _mapController.pointToLatLng(
              CustomPoint((mapSize.width / 2) + 1, mapSize.height / 2),
            );
            _radius = const Distance(roundResult: false).distance(
                  _center!,
                  _mapController.pointToLatLng(
                    CustomPoint(
                      mapSize.width / 2,
                      (mapSize.height / 2) -
                          (mapSize.height - (mapSize.width + 10)),
                    ),
                  )!,
                ) /
                1000;

            /*print(_center.toString());
            print(_radius.toString());
            print(
              CircleRegion(
                _center!,
                _radius!,
              ).toList(),
            );*/

            _pointTL = _center;
            _pointBR = _mapController.pointToLatLng(
              CustomPoint(
                mapSize.width / 2,
                (mapSize.height / 2) - (mapSize.height - (mapSize.width + 10)),
              ),
            );
          },
        );
        break;
    }
  }

  Future<void> _countTiles() async {
    if (Provider.of<GeneralProvider>(context, listen: false).currentStore !=
        null) {
      final DownloadProvider provider =
          Provider.of<DownloadProvider>(context, listen: false);

      provider
        ..regionTiles = null
        ..regionTiles = await FMTC.instance('').download.check(
              RectangleRegion(
                LatLngBounds(_pointTL, _pointBR),
              ).toDownloadable(
                provider.minZoom,
                provider.maxZoom,
                TileLayerOptions(),
              ),
            );
    }
  }
}
