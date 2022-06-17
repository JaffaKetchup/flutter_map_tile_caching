import 'dart:async';
import 'dart:math';

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
  static const double shapePadding = 15;
  static const crosshairsMovement = Point<double>(10, 10);

  final _mapKey = GlobalKey<State<StatefulWidget>>();
  late final MapController _mapController;

  late final StreamSubscription _polygonVisualizerStream;
  late final StreamSubscription _tileCounterTriggerStream;
  late final StreamSubscription _manualPolygonRecalcTriggerStream;

  Point<double>? _crosshairsTop;
  Point<double>? _crosshairsBottom;
  LatLng? _coordsTopLeft;
  LatLng? _coordsBottomRight;
  LatLng? _center;
  double? _radius;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _polygonVisualizerStream =
        _mapController.mapEventStream.listen((_) => _updatePointLatLng());
    _tileCounterTriggerStream = _mapController.mapEventStream
        .debounce(const Duration(seconds: 1))
        .listen((_) => _countTiles());

    Future.delayed(Duration.zero, () async {
      _manualPolygonRecalcTriggerStream =
          Provider.of<DownloadProvider>(context, listen: false)
              .manualPolygonRecalcTrigger
              .stream
              .listen((_) {
        _updatePointLatLng();
        _countTiles();
      });

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
    _manualPolygonRecalcTriggerStream.cancel();
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

              final String urlTemplate =
                  generalProvider.currentStore != null && metadata.data != null
                      ? metadata.data!['sourceURL']!
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
                    nonRotatedChildren: [
                      AttributionWidget.defaultWidget(
                        source: Uri.parse(urlTemplate).host,
                      ),
                    ],
                    children: [
                      TileLayerWidget(
                        options: TileLayerOptions(
                          urlTemplate: urlTemplate,
                          maxZoom: 20,
                          reset: generalProvider.resetController.stream,
                          keepBuffer: 5,
                          backgroundColor: const Color(0xFFaad3df),
                          tileBuilder: (context, widget, tile) =>
                              FutureBuilder<bool?>(
                            future: generalProvider.currentStore == null
                                ? Future.sync(() => null)
                                : FMTC
                                    .instance(generalProvider.currentStore!)
                                    .getTileProvider()
                                    .checkTileCachedAsync(
                                      coords: tile.coords,
                                      options: TileLayerOptions(
                                        urlTemplate: urlTemplate,
                                      ),
                                    ),
                            builder: (context, snapshot) => DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                color: (snapshot.data ?? false)
                                    ? Colors.deepOrange.withOpacity(0.33)
                                    : Colors.transparent,
                              ),
                              child: widget,
                            ),
                          ),
                        ),
                      ),
                      if (_coordsTopLeft != null &&
                          _coordsBottomRight != null &&
                          downloadProvider.regionMode != RegionMode.circle)
                        PolygonLayerWidget(
                          options: PolygonLayerOptions(
                            polygons: [
                              Polygon(
                                points: RectangleRegion(
                                  LatLngBounds(
                                    _coordsTopLeft,
                                    _coordsBottomRight,
                                  ),
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
                  if (_crosshairsTop != null && _crosshairsBottom != null) ...[
                    Positioned(
                      top: _crosshairsTop!.y,
                      left: _crosshairsTop!.x,
                      child: const Crosshairs(),
                    ),
                    Positioned(
                      top: _crosshairsBottom!.y,
                      left: _crosshairsBottom!.x,
                      child: const Crosshairs(),
                    ),
                  ]
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
    final mapCenter = Point<double>(mapSize.width / 2, mapSize.height / 2);

    late final Point<double> calculatedTopLeft;
    late final Point<double> calculatedBottomRight;

    switch (downloadProvider.regionMode) {
      case RegionMode.square:
        final allowedArea = Size.square(mapSize.width - (shapePadding * 2));
        calculatedTopLeft = Point<double>(
          shapePadding,
          mapCenter.y - allowedArea.height / 2,
        );
        calculatedBottomRight = Point<double>(
          mapSize.width - shapePadding,
          mapCenter.y + allowedArea.height / 2,
        );
        break;
      case RegionMode.rectangleVertical:
        final allowedArea = Size(
          mapSize.width - (shapePadding * 2),
          mapSize.height - (shapePadding * 2) - 50,
        );
        calculatedTopLeft = Point<double>(
          shapePadding,
          mapCenter.y - allowedArea.height / 2,
        );
        calculatedBottomRight = Point<double>(
          mapSize.width - shapePadding,
          mapCenter.y + allowedArea.height / 2,
        );
        break;
      case RegionMode.rectangleHorizontal:
        final allowedArea = Size(
          mapSize.width - (shapePadding * 2),
          (mapSize.width - (shapePadding * 2)) / 1.75,
        );
        calculatedTopLeft = Point<double>(
          shapePadding,
          mapCenter.y - allowedArea.height / 2,
        );
        calculatedBottomRight = Point<double>(
          mapSize.width - shapePadding,
          mapCenter.y + allowedArea.height / 2,
        );
        break;
      case RegionMode.circle:
        final allowedArea = Size.square(mapSize.width - (shapePadding * 2));

        final calculatedTop = Point<double>(
          mapCenter.x,
          mapCenter.y - allowedArea.height / 2,
        );

        _crosshairsTop = calculatedTop - crosshairsMovement;
        _crosshairsBottom = mapCenter - crosshairsMovement;

        _center = _mapController.pointToLatLng(customPointFromPoint(mapCenter));
        _radius = const Distance(roundResult: false).distance(
              _center!,
              _mapController
                  .pointToLatLng(customPointFromPoint(calculatedTop))!,
            ) /
            1000;
        setState(() {});
        break;
    }

    if (downloadProvider.regionMode != RegionMode.circle) {
      _crosshairsTop = calculatedTopLeft - crosshairsMovement;
      _crosshairsBottom = calculatedBottomRight - crosshairsMovement;

      _coordsTopLeft =
          _mapController.pointToLatLng(customPointFromPoint(calculatedTopLeft));
      _coordsBottomRight = _mapController
          .pointToLatLng(customPointFromPoint(calculatedBottomRight));

      setState(() {});
    }

    downloadProvider.region = downloadProvider.regionMode == RegionMode.circle
        ? CircleRegion(_center!, _radius!)
        : RectangleRegion(
            LatLngBounds(_coordsTopLeft, _coordsBottomRight),
          );
  }

  Future<void> _countTiles() async {
    final DownloadProvider provider =
        Provider.of<DownloadProvider>(context, listen: false);

    if (Provider.of<GeneralProvider>(context, listen: false).currentStore !=
            null &&
        provider.region != null) {
      provider
        ..regionTiles = null
        ..regionTiles = await FMTC.instance('').download.check(
              provider.region!.toDownloadable(
                provider.minZoom,
                provider.maxZoom,
                TileLayerOptions(),
              ),
            );
    }
  }
}

CustomPoint<E> customPointFromPoint<E extends num>(Point<E> point) =>
    CustomPoint(point.x, point.y);
