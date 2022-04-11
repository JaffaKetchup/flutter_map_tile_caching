import 'dart:async';

import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/back_layer.dart';
import 'components/front_layer.dart';
import 'components/region_constraints.dart';
import 'components/scaffold_features.dart';
import 'components/xy_to_latlng.dart';

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
    mapSource ??= context
            .read<GeneralProvider>()
            .persistent!
            .getString('${mcm!._storeName}: sourceURL') ??
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      revealBackLayerAtStart: true,
      headerHeight: 0,
      appBar: buildAppBar(),
      floatingActionButton: FAB(
        mcm: mcm!,
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

              return BackLayer(
                controller: controller,
                mcm: mcm,
                mapSource: mapSource,
                animationDuration: animationDuration,
                region: region,
                selectedRegionMode: selectedRegionMode,
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
                      setState(() => selectedRegionShape = key);
                      Navigator.of(context).pop();
                    }
                  : null,
              enabled: i != regionShapes.length - 1,
            );
          },
          separatorBuilder: (context, i) =>
              i == regionShapes.length - 2 ? const Divider() : Container(),
        ),
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

const Map<String, List<dynamic>> regionShapes = {
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
