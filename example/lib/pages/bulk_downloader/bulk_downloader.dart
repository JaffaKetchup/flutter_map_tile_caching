import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:fmtc_example/state/general_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../state/bulk_download_provider.dart';
import 'components/panel/panel.dart';
import 'components/scaffold_features.dart';
import 'components/map.dart';
import 'components/region_constraints.dart';
import 'components/region_mode.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mcm ??= ModalRoute.of(context)!.settings.arguments as MapCachingManager;

    mapSource ??= Provider.of<GeneralProvider>(context, listen: false)
            .persistent!
            .getString('${mcm!.storeName}: sourceURL') ??
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkDownloadProvider>(
      builder: (context, bdp, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: buildAppBar(context),
          floatingActionButton: !bdp.regionSelected ? FAB(mcm: mcm!) : null,
          body: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              LayoutBuilder(
                builder: (context, screenConstraints) {
                  bdp.region = RegionConstraints(
                    screenConstraints: screenConstraints.deflate(
                      EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).viewPadding.bottom + 72),
                    ),
                    isNonSquare: bdp.mode == RegionMode.Rectangle,
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
                                duration: animationDuration,
                                top: bdp.region?.top,
                                left: bdp.region?.left,
                                child: AnimatedContainer(
                                  height: bdp.region?.height,
                                  width: bdp.region?.width,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius:
                                        bdp.mode == RegionMode.Circle &&
                                                bdp.region != null
                                            ? BorderRadius.circular(
                                                (bdp.region?.width ?? 2) / 2)
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
                          ignoring: !bdp.regionSelected,
                          child: AnimatedContainer(
                            duration: animationDuration,
                            color: bdp.regionSelected
                                ? Colors.black.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      if (bdp.regionSelected)
                        GestureDetector(
                          onTap: () => bdp.regionSelected = false,
                        ),
                    ],
                  );
                },
              ),
              AnimatedPositioned(
                bottom: bdp.regionSelected
                    ? -(MediaQuery.of(context).viewPadding.bottom + 50)
                    : 10,
                left: 10,
                height: MediaQuery.of(context).viewPadding.bottom + 68,
                right: 10 + 72,
                child: const RegionModeChips(),
                duration: animationDuration * 2,
                curve: Curves.easeInOut,
              ),
              AnimatedPositioned(
                bottom: bdp.regionSelected
                    ? 0
                    : -(MediaQuery.of(context).size.height / 2 + 16),
                height: MediaQuery.of(context).size.height / 2 + 16,
                width: MediaQuery.of(context).size.width,
                child: Panel(
                  mcm: mcm!,
                  controller: controller,
                  mapSource: mapSource,
                ),
                duration: animationDuration * 2,
                curve: Curves.easeInOut,
              ),
            ],
          ),
        );
      },
    );
  }
}
