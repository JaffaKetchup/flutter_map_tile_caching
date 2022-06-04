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

  LatLng? _rectTopLeft;
  LatLng? _rectBottomRight;

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
  Widget build(BuildContext context) => Consumer<GeneralProvider>(
        key: _mapKey,
        builder: (context, provider, _) => FutureBuilder<Map<String, String>?>(
          future: provider.currentStore == null
              ? Future.sync(() => {})
              : FMTC.instance(provider.currentStore!).metadata.readAsync,
          builder: (context, metadata) {
            if (!metadata.hasData ||
                metadata.data == null ||
                (provider.currentStore != null &&
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
                        urlTemplate: provider.currentStore != null &&
                                metadata.data != null
                            ? metadata.data!['sourceURL']!
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        maxZoom: 20,
                        reset: provider.resetController.stream,
                        keepBuffer: 5,
                        backgroundColor: const Color(0xFFaad3df),
                      ),
                    ),
                    if (_rectTopLeft != null && _rectBottomRight != null)
                      PolygonLayerWidget(
                        options: PolygonLayerOptions(
                          polygons: [
                            Polygon(
                              points: RectangleRegion(
                                LatLngBounds(_rectTopLeft, _rectBottomRight),
                              ).toList(),
                              isFilled: true,
                              color: Colors.green.withOpacity(0.5),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
                const Positioned(
                  top: 15,
                  left: 15,
                  child: Crosshairs(),
                ),
                const Positioned(
                  bottom: 15,
                  right: 15,
                  child: Crosshairs(),
                ),
              ],
            );
          },
        ),
      );

  void _updatePointLatLng() => setState(
        () {
          _rectTopLeft =
              _mapController.pointToLatLng(const CustomPoint(23, 23));
          _rectBottomRight = _mapController.pointToLatLng(
            CustomPoint(
              _mapKey.currentContext!.size!.width - 23,
              _mapKey.currentContext!.size!.height - 23,
            ),
          );
        },
      );

  Future<void> _countTiles() async {
    if (Provider.of<GeneralProvider>(context, listen: false).currentStore !=
        null) {
      final DownloadProvider provider =
          Provider.of<DownloadProvider>(context, listen: false);

      provider
        ..regionTiles = null
        ..regionTiles = await FMTC.instance('').download.check(
              RectangleRegion(
                LatLngBounds(_rectTopLeft, _rectBottomRight),
              ).toDownloadable(
                provider.minZoom,
                provider.maxZoom,
                TileLayerOptions(),
              ),
            );
    }
  }
}
