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
import '../../map/build_attribution.dart';
import 'crosshairs.dart';

class MapView extends StatefulWidget {
  const MapView({
    super.key,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  static const double _shapePadding = 15;
  static const _crosshairsMovement = Point<double>(10, 10);

  final _mapKey = GlobalKey<State<StatefulWidget>>();
  final MapController _mapController = MapController();

  late final StreamSubscription _polygonVisualizerStream;
  late final StreamSubscription _tileCounterTriggerStream;
  late final StreamSubscription _manualPolygonRecalcTriggerStream;

  Point<double>? _crosshairsTop;
  Point<double>? _crosshairsBottom;
  LatLng? _coordsTopLeft;
  LatLng? _coordsBottomRight;
  LatLng? _center;
  double? _radius;

  PolygonLayer _buildTargetPolygon(BaseRegion region) => PolygonLayer(
        polygons: [
          Polygon(
            points: [
              LatLng(-90, 180),
              LatLng(90, 180),
              LatLng(90, -180),
              LatLng(-90, -180),
            ],
            holePointsList: [region.toOutline()],
            isFilled: true,
            borderColor: Colors.black,
            borderStrokeWidth: 2,
            color: Theme.of(context).colorScheme.background.withOpacity(2 / 3),
          ),
        ],
      );

  @override
  void initState() {
    super.initState();

    _manualPolygonRecalcTriggerStream =
        Provider.of<DownloadProvider>(context, listen: false)
            .manualPolygonRecalcTrigger
            .stream
            .listen((_) {
      _updatePointLatLng();
      _countTiles();
    });

    _polygonVisualizerStream =
        _mapController.mapEventStream.listen((_) => _updatePointLatLng());
    _tileCounterTriggerStream = _mapController.mapEventStream
        .debounce(const Duration(seconds: 1))
        .listen((_) => _countTiles());
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
            FutureBuilder<Map<String, String>?>(
          future: generalProvider.currentStore == null
              ? Future.sync(() => {})
              : FMTC.instance(generalProvider.currentStore!).metadata.readAsync,
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
                    maxZoom: 22,
                    maxBounds: LatLngBounds.fromPoints([
                      LatLng(-90, 180),
                      LatLng(90, 180),
                      LatLng(90, -180),
                      LatLng(-90, -180),
                    ]),
                    interactiveFlags:
                        InteractiveFlag.all & ~InteractiveFlag.rotate,
                    scrollWheelVelocity: 0.002,
                    keepAlive: true,
                    onMapReady: () {
                      _updatePointLatLng();
                      _countTiles();
                    },
                  ),
                  nonRotatedChildren: buildStdAttribution(
                    urlTemplate,
                    alignment: AttributionAlignment.bottomLeft,
                  ),
                  children: [
                    TileLayer(
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
                                  coords: tile.coordinates,
                                  options: TileLayer(
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
                    if (_coordsTopLeft != null &&
                        _coordsBottomRight != null &&
                        downloadProvider.regionMode != RegionMode.circle)
                      _buildTargetPolygon(
                        RectangleRegion(
                          LatLngBounds(_coordsTopLeft!, _coordsBottomRight!),
                        ),
                      )
                    else if (_center != null &&
                        _radius != null &&
                        downloadProvider.regionMode == RegionMode.circle)
                      _buildTargetPolygon(CircleRegion(_center!, _radius!))
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
      );

  void _updatePointLatLng() {
    final DownloadProvider downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    final Size mapSize = _mapKey.currentContext!.size!;
    final bool isHeightLongestSide = mapSize.width < mapSize.height;

    final centerNormal = Point<double>(mapSize.width / 2, mapSize.height / 2);
    final centerInversed = Point<double>(mapSize.height / 2, mapSize.width / 2);

    late final Point<double> calculatedTopLeft;
    late final Point<double> calculatedBottomRight;

    switch (downloadProvider.regionMode) {
      case RegionMode.square:
        final double offset = (mapSize.shortestSide - (_shapePadding * 2)) / 2;

        calculatedTopLeft = Point<double>(
          centerNormal.x - offset,
          centerNormal.y - offset,
        );
        calculatedBottomRight = Point<double>(
          centerNormal.x + offset,
          centerNormal.y + offset,
        );
        break;
      case RegionMode.rectangleVertical:
        final allowedArea = Size(
          mapSize.width - (_shapePadding * 2),
          (mapSize.height - (_shapePadding * 2)) / 1.5 - 50,
        );

        calculatedTopLeft = Point<double>(
          centerInversed.y - allowedArea.shortestSide / 2,
          _shapePadding,
        );
        calculatedBottomRight = Point<double>(
          centerInversed.y + allowedArea.shortestSide / 2,
          mapSize.height - _shapePadding - 25,
        );
        break;
      case RegionMode.rectangleHorizontal:
        final allowedArea = Size(
          mapSize.width - (_shapePadding * 2),
          (mapSize.width < mapSize.height + 250)
              ? (mapSize.width - (_shapePadding * 2)) / 1.75
              : (mapSize.height - (_shapePadding * 2) - 0),
        );

        calculatedTopLeft = Point<double>(
          _shapePadding,
          centerNormal.y - allowedArea.height / 2,
        );
        calculatedBottomRight = Point<double>(
          mapSize.width - _shapePadding,
          centerNormal.y + allowedArea.height / 2 - 25,
        );
        break;
      case RegionMode.circle:
        final allowedArea =
            Size.square(mapSize.shortestSide - (_shapePadding * 2));

        final calculatedTop = Point<double>(
          centerNormal.x,
          (isHeightLongestSide ? centerNormal.y : centerInversed.x) -
              allowedArea.width / 2,
        );

        _crosshairsTop = calculatedTop - _crosshairsMovement;
        _crosshairsBottom = centerNormal - _crosshairsMovement;

        _center =
            _mapController.pointToLatLng(_customPointFromPoint(centerNormal));
        _radius = const Distance(roundResult: false).distance(
              _center!,
              _mapController
                  .pointToLatLng(_customPointFromPoint(calculatedTop))!,
            ) /
            1000;
        setState(() {});
        break;
    }

    if (downloadProvider.regionMode != RegionMode.circle) {
      _crosshairsTop = calculatedTopLeft - _crosshairsMovement;
      _crosshairsBottom = calculatedBottomRight - _crosshairsMovement;

      _coordsTopLeft = _mapController
          .pointToLatLng(_customPointFromPoint(calculatedTopLeft));
      _coordsBottomRight = _mapController
          .pointToLatLng(_customPointFromPoint(calculatedBottomRight));

      setState(() {});
    }

    downloadProvider.region = downloadProvider.regionMode == RegionMode.circle
        ? CircleRegion(_center!, _radius!)
        : RectangleRegion(
            LatLngBounds(_coordsTopLeft!, _coordsBottomRight!),
          );
  }

  Future<void> _countTiles() async {
    final DownloadProvider provider =
        Provider.of<DownloadProvider>(context, listen: false);

    if (provider.region != null) {
      provider
        ..regionTiles = null
        ..regionTiles = await FMTC.instance('').download.check(
              provider.region!.toDownloadable(
                provider.minZoom,
                provider.maxZoom,
                TileLayer(),
              ),
            );
    }
  }
}

CustomPoint<E> _customPointFromPoint<E extends num>(Point<E> point) =>
    CustomPoint(point.x, point.y);
