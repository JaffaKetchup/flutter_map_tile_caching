import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:fmtc_example/pages/bulk_downloader/components/region_mode.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/constraints.dart';
import 'components/map.dart';
import 'components/panel.dart';

class BulkDownloader extends StatefulWidget {
  const BulkDownloader({Key? key}) : super(key: key);

  @override
  _BulkDownloaderState createState() => _BulkDownloaderState();
}

class _BulkDownloaderState extends State<BulkDownloader> {
  final MapController controller = MapController();
  MapCachingManager? mcm;

  LatLngBounds? rectBounds;
  LatLng? circleCenter;
  double? circleRadius;

  RegionMode selectedRegionMode = RegionMode.Square;
  Constraints? constSelected;

  bool debug = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final LatLng center = controller.center;
      final double zoom = controller.zoom;
      controller.move(LatLng(0, 0), 10);
      controller.move(center, zoom);

      Future.delayed(const Duration(milliseconds: 1), () {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: Consumer<GeneralProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, screenConstraints) {
                    constSelected = regionModeBranch<Constraints>(
                      selectedRegionMode,
                      {
                        RegionMode.Square:
                            SquareConstraints(screenConstraints, 40),
                        RegionMode.Rectangle:
                            RectangleConstraints(screenConstraints, 40),
                        RegionMode.Circle:
                            SquareConstraints(screenConstraints, 40),
                      },
                    );

                    return Stack(
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
                                  duration: const Duration(milliseconds: 200),
                                  top: constSelected?.top,
                                  left: constSelected?.left,
                                  child: AnimatedContainer(
                                    height: constSelected?.height,
                                    width: constSelected?.width,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: selectedRegionMode ==
                                              RegionMode.Circle
                                          ? BorderRadius.circular(
                                              (constSelected?.width ?? 2) / 2)
                                          : null,
                                    ),
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (true) ...[
                          Positioned(
                            top: constSelected?.top,
                            left: constSelected?.left,
                            width: 5,
                            height: 5,
                            child: Container(color: Colors.red),
                          ),
                          Positioned(
                            top: constSelected?.bottomRight.dy,
                            left: constSelected?.bottomRight.dx,
                            width: 5,
                            height: 5,
                            child: Container(color: Colors.yellow),
                          ),
                          Positioned(
                            top: constSelected?.edgeCenter.dy,
                            left: constSelected?.edgeCenter.dx,
                            width: 5,
                            height: 5,
                            child: Container(color: Colors.green),
                          ),
                          Positioned(
                            top: constSelected?.middleCenter.dy,
                            left: constSelected?.middleCenter.dx,
                            width: 5,
                            height: 5,
                            child: Container(color: Colors.blue),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              Panel(
                key: UniqueKey(),
                mcm: mcm!,
                controller: controller,
                constraints: constSelected,
                regionTypeIndex: selectedRegionMode.index,
                regionTypeChangedCallback: (i) {
                  setState(() => selectedRegionMode = RegionMode.values[i]);
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    final LatLng center = controller.center;
                    final double zoom = controller.zoom;
                    controller.move(LatLng(0, 0), 10);
                    controller.move(center, zoom);
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
