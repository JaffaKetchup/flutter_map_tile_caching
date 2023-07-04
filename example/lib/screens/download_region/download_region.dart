import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
//import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/state/download_provider.dart';
import '../../shared/state/general_provider.dart';
import 'components/bd_battery_optimizations_info.dart';
import 'components/buffering_configuration.dart';
import 'components/optional_functionality.dart';
import 'components/region_information.dart';
import 'components/section_separator.dart';
import 'components/store_selector.dart';
import 'components/usage_warning.dart';

class DownloadRegionPopup extends StatefulWidget {
  const DownloadRegionPopup({
    super.key,
    required this.region,
  });

  final BaseRegion region;

  @override
  State<DownloadRegionPopup> createState() => _DownloadRegionPopupState();
}

class _DownloadRegionPopupState extends State<DownloadRegionPopup> {
  late final CircleRegion? circleRegion;
  late final RectangleRegion? rectangleRegion;

  @override
  void initState() {
    if (widget.region is CircleRegion) {
      circleRegion = widget.region as CircleRegion;
      rectangleRegion = null;
    } else {
      rectangleRegion = widget.region as RectangleRegion;
      circleRegion = null;
    }

    super.initState();
  }

  @override
  void didChangeDependencies() {
    final String? currentStore =
        Provider.of<GeneralProvider>(context, listen: false).currentStore;
    if (currentStore != null) {
      Provider.of<DownloadProvider>(context, listen: false)
          .setSelectedStore(FMTC.instance(currentStore), notify: false);
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => Consumer<DownloadProvider>(
        builder: (context, provider, _) => Scaffold(
          appBar: AppBar(title: const Text('Configure Bulk Download')),
          floatingActionButton: provider.selectedStore == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    final Map<String, String> metadata =
                        await provider.selectedStore!.metadata.readAsync;

                    provider.setDownloadProgress(
                      provider.selectedStore!.download
                          .startForeground(
                            region: widget.region.toDownloadable(
                              provider.minZoom,
                              provider.maxZoom,
                              TileLayer(
                                urlTemplate: metadata['sourceURL'],
                                userAgentPackageName:
                                    'dev.jaffaketchup.fmtc.demo',
                              ),
                            ),
                            parallelThreads:
                                (await SharedPreferences.getInstance()).getBool(
                                          'bypassDownloadThreadsLimitation',
                                        ) ??
                                        false
                                    ? 10
                                    : 2,
                            maxBufferLength: provider.bufferingAmount,
                            pruneExistingTiles: provider.preventRedownload,
                            pruneSeaTiles: provider.seaTileRemoval,
                            disableRecovery: provider.disableRecovery,
                          )
                          .asBroadcastStream(),
                    );

                    if (mounted) Navigator.of(context).pop();
                  },
                  label: const Text('Start Download'),
                  icon: const Icon(Icons.save),
                ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegionInformation(
                    widget: widget,
                    circleRegion: circleRegion,
                    rectangleRegion: rectangleRegion,
                  ),
                  const SectionSeparator(),
                  const StoreSelector(),
                  const SectionSeparator(),
                  const OptionalFunctionality(),
                  const SectionSeparator(),
                  const BufferingConfiguration(),
                  const SectionSeparator(),
                  const BackgroundDownloadBatteryOptimizationsInfo(),
                  const SectionSeparator(),
                  const UsageWarning(),
                ],
              ),
            ),
          ),
        ),
      );
}
