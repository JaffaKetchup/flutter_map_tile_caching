import 'dart:async';

import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fmtc_example/pages/bulk_downloader/components/xy_to_latlng.dart';
import 'package:fmtc_example/state/general_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'components/map.dart';
import 'components/region_constraints.dart';
import 'components/scaffold_features.dart';
import 'package:latlong2/latlong.dart';

class BulkDownloader extends StatefulWidget {
  const BulkDownloader({Key? key}) : super(key: key);

  @override
  _BulkDownloaderState createState() => _BulkDownloaderState();
}

class _BulkDownloaderState extends State<BulkDownloader> {
  static const Duration animationDuration = Duration(milliseconds: 200);

  final MapController controller = MapController();

  MapCachingManager? mcm;
  String? mapSource;

  static const Map<String, List<dynamic>> regionShapes = {
    'Square': [
      Icons.crop_square_sharp,
      RegionMode.square,
    ],
    'Rectangle (Vertical)': [
      Icons.crop_portrait_sharp,
      RegionMode.rectangleVertical,
    ],
    'Rectangle (Horizontal)': [
      Icons.crop_landscape_sharp,
      RegionMode.rectangleHorizontal,
    ],
    'Circle': [
      Icons.circle_outlined,
      RegionMode.circle,
    ],
    'Line/Path': [
      Icons.timeline,
      null,
    ],
  };
  String selectedRegionShape = 'Square';
  RegionMode get selectedRegionMode => regionShapes[selectedRegionShape]![1];

  late RegionConstraints region;

  final StreamController<Future<List<LatLng>>> refreshDownloadTileCounter =
      StreamController.broadcast();

  @override
  void dispose() {
    super.dispose();
    refreshDownloadTileCounter.close();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager;

    mapSource ??= Provider.of<GeneralProvider>(context, listen: false)
            .persistent!
            .getString('${mcm!.storeName}: sourceURL') ??
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      revealBackLayerAtStart: true,
      headerHeight: 0,
      appBar: buildAppBar(),
      floatingActionButton: FAB(
        calculateCornersCallback: () async {
          refreshDownloadTileCounter.add(
            Future.wait(
              [
                xyToLatLng(
                  controller: controller,
                  offset: (selectedRegionMode == RegionMode.circle
                          ? region.middleCenter
                          : region.topLeft) -
                      Offset(0,
                          (MediaQuery.of(context).viewPadding.bottom + 72) / 2),
                  height: region.screenConstraints.maxHeight,
                  width: region.screenConstraints.maxWidth,
                ),
                xyToLatLng(
                  controller: controller,
                  offset: (selectedRegionMode == RegionMode.circle
                          ? region.edgeCenter
                          : region.bottomRight) -
                      Offset(0,
                          (MediaQuery.of(context).viewPadding.bottom + 72) / 2),
                  height: region.screenConstraints.maxHeight,
                  width: region.screenConstraints.maxWidth,
                ),
              ],
            ),
          );

          return;
        },
      ),
      frontLayer: FrontLayer(
        mapSource: mapSource!,
        rdtc: refreshDownloadTileCounter.stream,
        regionMode: selectedRegionMode,
      ),
      backLayer: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          LayoutBuilder(
            builder: (context, screenConstraints) {
              region = RegionConstraints(
                screenConstraints: screenConstraints.deflate(
                  EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom + 72,
                  ),
                ),
                mode: selectedRegionMode,
              );

              return ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  children: [
                    MapView(
                      controller: controller,
                      mcm: mcm!,
                    ),
                    IgnorePointer(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.srcOut,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                backgroundBlendMode: BlendMode.dstOut,
                              ),
                            ),
                            AnimatedPositioned(
                              duration: animationDuration,
                              top: region.top,
                              left: region.left,
                              child: AnimatedContainer(
                                height: region.height,
                                width: region.width,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: selectedRegionMode ==
                                          RegionMode.circle
                                      ? BorderRadius.circular(region.width / 2)
                                      : null,
                                ),
                                duration: animationDuration,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: Backdrop.of(context).isBackLayerRevealed,
                        child: AnimatedContainer(
                          duration: animationDuration,
                          color: Backdrop.of(context).isBackLayerConcealed
                              ? Colors.black.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  DownloadAppBar buildAppBar() {
    return DownloadAppBar(
      builder: (context) => BackdropAppBar(
        title: const Text('Download Region'),
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (Backdrop.of(context).isBackLayerConcealed)
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: () => Backdrop.of(context).revealBackLayer(),
                tooltip: 'Re-Select Area',
              ),
          ],
        ),
        leadingWidth:
            Backdrop.of(context).isBackLayerRevealed ? 56 : 56 * 2 - 8,
        actions: [
          if (Backdrop.of(context).isBackLayerRevealed)
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => buildShapeSelectorMenu(),
                );
              },
              icon: const Icon(Icons.app_registration),
              tooltip: 'Select Region Shape',
            ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: buildInfoPanel,
              );
            },
            icon: const Icon(Icons.help),
            tooltip: 'Show Help Panel',
          ),
        ],
      ),
    );
  }

  SafeArea buildShapeSelectorMenu() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.separated(
          itemCount: regionShapes.length,
          shrinkWrap: true,
          itemBuilder: (context, i) {
            final String key = regionShapes.keys.toList()[i];
            final IconData icon = regionShapes.values.toList()[i][0];

            return ListTile(
              visualDensity: VisualDensity.compact,
              title: Text(key),
              subtitle: i == regionShapes.length - 1
                  ? const Text('Disabled in example application')
                  : null,
              leading: Icon(icon),
              trailing:
                  selectedRegionShape == key ? const Icon(Icons.done) : null,
              onTap: i != regionShapes.length - 1
                  ? () {
                      setState(() {
                        selectedRegionShape = key;
                      });
                      Navigator.of(context).pop();
                    }
                  : null,
            );
          },
          separatorBuilder: (context, i) =>
              i == regionShapes.length - 2 ? const Divider() : Container(),
        ),
      ),
    );
  }
}

class FAB extends StatelessWidget {
  const FAB({
    Key? key,
    required this.calculateCornersCallback,
  }) : super(key: key);

  final Future<void> Function() calculateCornersCallback;

  @override
  Widget build(BuildContext context) {
    if (Backdrop.of(context).isBackLayerRevealed) {
      return FloatingActionButton(
        onPressed: () async {
          await calculateCornersCallback();
          Backdrop.of(context).concealBackLayer();
        },
        child: const Icon(Icons.done),
      );
    } else {
      return SpeedDial(
        tooltip: 'Download Region',
        icon: Icons.download,
        activeIcon: Icons.cancel,
        children: [
          SpeedDialChild(
            label: 'Download In Foreground',
            child: const Icon(Icons.download),
          ),
          SpeedDialChild(
            label: 'Download In Background',
            child: const Icon(Icons.miscellaneous_services),
          ),
        ],
      );
    }
  }
}

class FrontLayer extends StatefulWidget {
  const FrontLayer({
    Key? key,
    required this.rdtc,
    required this.regionMode,
    required this.mapSource,
  }) : super(key: key);

  final Stream<Future<List<LatLng>>> rdtc;
  final RegionMode regionMode;
  final String mapSource;

  @override
  _FrontLayerState createState() => _FrontLayerState();
}

class _FrontLayerState extends State<FrontLayer> {
  static const Distance distance = Distance(roundResult: false);

  Future<List<LatLng>>? streamEvt;

  @override
  void initState() {
    super.initState();
    widget.rdtc.listen((e) => setState(() {
          streamEvt = e;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: FutureBuilder<List<LatLng>>(
        future: streamEvt,
        builder: (context, coords) {
          if (!coords.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          late final DownloadableRegion region;

          if (widget.regionMode == RegionMode.circle) {
            region = CircleRegion(
              coords.data![0],
              distance.distance(coords.data![0], coords.data![1]) / 1000,
            ).toDownloadable(
              1,
              16,
              TileLayerOptions(urlTemplate: widget.mapSource),
            );
          } else {
            region = RectangleRegion(
              LatLngBounds(coords.data![0], coords.data![1]),
            ).toDownloadable(
              1,
              16,
              TileLayerOptions(urlTemplate: widget.mapSource),
            );
          }

          return FutureBuilder<int>(
            future: StorageCachingTileProvider.checkRegion(region),
            builder: (context, tiles) {
              if (tiles.connectionState != ConnectionState.done) {
                return SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Counting Estimated Tiles'),
                    ],
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tiles.data!.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const Text('est. tiles'),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ((tiles.data! * 20) / 1024).toStringAsFixed(0) + 'MiB',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const Text('avg. storage'),
                    ],
                  ),
                  Expanded(child: Text(coords.data.toString())),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

enum RegionMode {
  square,
  rectangleVertical,
  rectangleHorizontal,
  circle,
}
