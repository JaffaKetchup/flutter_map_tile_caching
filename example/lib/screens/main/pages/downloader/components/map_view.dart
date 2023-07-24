import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:gpx/gpx.dart';
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

  late final DownloadProvider downloadProvider;

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
              const LatLng(-90, 180),
              const LatLng(90, 180),
              const LatLng(90, -180),
              const LatLng(-90, -180),
            ],
            holePointsList: [region.toOutline().toList()],
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

    downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    _manualPolygonRecalcTriggerStream =
        downloadProvider.manualPolygonRecalcTrigger.stream.listen((_) {
      if (downloadProvider.regionMode == RegionMode.line) {
        _updateLineRegion();
        return;
      }
      _updatePointLatLng();
      _countTiles();
    });

    _polygonVisualizerStream = _mapController.mapEventStream.listen((_) {
      if (downloadProvider.regionMode != RegionMode.line) {
        _updatePointLatLng();
      }
    });

    _tileCounterTriggerStream = _mapController.mapEventStream
        .debounce(const Duration(seconds: 1))
        .listen((_) {
      if (downloadProvider.regionMode != RegionMode.line) _countTiles();
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
                    initialCenter: const LatLng(51.509364, -0.128928),
                    initialZoom: 9.2,
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
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      scrollWheelVelocity: 0.002,
                    ),
                    onMapReady: () {
                      _updatePointLatLng();
                      _countTiles();
                    },
                    onTap: (_, point) => _addLinePoint(point),
                    onSecondaryTap: (_, point) => _removeLinePoint(),
                    onLongPress: (_, point) => _removeLinePoint(),
                    keepAlive: true,
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
                      userAgentPackageName: 'dev.jaffaketchup.fmtc.demo',
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
                    if (downloadProvider.regionMode == RegionMode.line)
                      LineRegion(
                        downloadProvider.lineRegionPoints,
                        downloadProvider.lineRegionRadius,
                      ).toDrawable(
                        borderColor: Colors.black,
                        borderStrokeWidth: 2,
                        fillColor: Colors.green.withOpacity(2 / 3),
                        prettyPaint: false,
                      )
                    else if (_coordsTopLeft != null &&
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
                if (downloadProvider.regionMode != RegionMode.line &&
                    _crosshairsTop != null &&
                    _crosshairsBottom != null) ...[
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
                ],
                if (downloadProvider.regionMode == RegionMode.line)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          const Text('Radius'),
                          Expanded(
                            child: Slider(
                              value: downloadProvider.lineRegionRadius,
                              min: 50,
                              max: 5000,
                              divisions: 99,
                              label:
                                  '${downloadProvider.lineRegionRadius.round()} meters',
                              onChanged: (val) => setState(
                                () => downloadProvider.lineRegionRadius = val,
                              ),
                              onChangeEnd: (val) {
                                downloadProvider.lineRegionRadius = val;
                                _updateLineRegion();
                              },
                            ),
                          ),
                          const VerticalDivider(),
                          IconButton(
                            onPressed: () async {
                              await FilePicker.platform.clearTemporaryFiles();

                              late final FilePickerResult? result;
                              try {
                                result = await FilePicker.platform.pickFiles(
                                  dialogTitle: 'Parse From GPX',
                                  type: FileType.custom,
                                  allowedExtensions: ['gpx', 'kml'],
                                  allowMultiple: true,
                                );
                              } on PlatformException catch (_) {
                                result = await FilePicker.platform.pickFiles(
                                  dialogTitle: 'Parse From GPX',
                                  allowMultiple: true,
                                );
                              }

                              if (result != null) {
                                final gpxReader = GpxReader();
                                for (final path
                                    in result.files.map((e) => e.path)) {
                                  downloadProvider.lineRegionPoints.addAll(
                                    gpxReader
                                        .fromString(
                                          await File(path!).readAsString(),
                                        )
                                        .trks
                                        .map(
                                          (e) => e.trksegs.map(
                                            (e) => e.trkpts.map(
                                              (e) => LatLng(e.lat!, e.lon!),
                                            ),
                                          ),
                                        )
                                        .expand((e) => e)
                                        .expand((e) => e),
                                  );
                                  _updateLineRegion();
                                }
                              }
                            },
                            icon: const Icon(Icons.download),
                            tooltip: 'Import from GPX',
                          ),
                          IconButton(
                            onPressed: () {
                              downloadProvider.lineRegionPoints.clear();
                              _updateLineRegion();
                            },
                            icon: const Icon(Icons.cancel),
                            tooltip: 'Clear existing points',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  void _updateLineRegion() {
    downloadProvider.region = LineRegion(
      downloadProvider.lineRegionPoints,
      downloadProvider.lineRegionRadius,
    );

    _countTiles();
  }

  void _removeLinePoint() {
    if (downloadProvider.regionMode == RegionMode.line) {
      downloadProvider.lineRegionPoints.removeLast();
      _updateLineRegion();
    }
  }

  void _addLinePoint(LatLng coord) {
    if (downloadProvider.regionMode == RegionMode.line) {
      downloadProvider.lineRegionPoints.add(coord);
      _updateLineRegion();
    }
  }

  void _updatePointLatLng() {
    if (downloadProvider.regionMode == RegionMode.line) return;

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

        _center = _mapController.camera.pointToLatLng(centerNormal);
        _radius = const Distance(roundResult: false).distance(
              _center!,
              _mapController.camera.pointToLatLng(calculatedTop),
            ) /
            1000;
        setState(() {});
        break;
      case RegionMode.line:
        break;
    }

    if (downloadProvider.regionMode != RegionMode.circle) {
      _crosshairsTop = calculatedTopLeft - _crosshairsMovement;
      _crosshairsBottom = calculatedBottomRight - _crosshairsMovement;

      _coordsTopLeft = _mapController.camera.pointToLatLng(calculatedTopLeft);
      _coordsBottomRight =
          _mapController.camera.pointToLatLng(calculatedBottomRight);

      setState(() {});
    }

    downloadProvider.region = downloadProvider.regionMode == RegionMode.circle
        ? CircleRegion(_center!, _radius!)
        : RectangleRegion(
            LatLngBounds(_coordsTopLeft!, _coordsBottomRight!),
          );
  }

  Future<void> _countTiles() async {
    if (downloadProvider.region != null) {
      downloadProvider
        ..regionTiles = null
        ..regionTiles = await FMTC.instance('').download.check(
              downloadProvider.region!.toDownloadable(
                minZoom: downloadProvider.minZoom,
                maxZoom: downloadProvider.maxZoom,
                options: TileLayer(),
              ),
            );
    }
  }
}
