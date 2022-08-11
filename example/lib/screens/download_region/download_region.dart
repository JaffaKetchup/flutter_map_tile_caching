import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/state/download_provider.dart';
import '../../shared/state/general_provider.dart';
import 'components/bd_battery_optimizations_info.dart';
import 'components/optional_functionality.dart';
import 'components/region_information.dart';
import 'components/section_separator.dart';
import 'components/store_selector.dart';
import 'components/usage_warning.dart';

class DownloadRegionPopup extends StatefulWidget {
  const DownloadRegionPopup({
    Key? key,
    required this.region,
  }) : super(key: key);

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Download Region'),
        ),
        body: Scrollbar(
          child: SingleChildScrollView(
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
                  const BackgroundDownloadBatteryOptimizationsInfo(),
                  const SectionSeparator(),
                  const UsageWarning(),
                  const SectionSeparator(),
                  const Text('START DOWNLOAD IN'),
                  Consumer2<DownloadProvider, GeneralProvider>(
                    builder: (context, downloadProvider, generalProvider, _) =>
                        Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: downloadProvider.selectedStore == null
                                ? null
                                : () async {
                                    final Map<String, String> metadata =
                                        await downloadProvider
                                            .selectedStore!.metadata.readAsync;

                                    downloadProvider.setDownloadProgress(
                                      downloadProvider.selectedStore!.download
                                          .startForeground(
                                            region:
                                                widget.region.toDownloadable(
                                              downloadProvider.minZoom,
                                              downloadProvider.maxZoom,
                                              TileLayer(
                                                urlTemplate:
                                                    metadata['sourceURL'],
                                              ),
                                              preventRedownload:
                                                  downloadProvider
                                                      .preventRedownload,
                                              seaTileRemoval: downloadProvider
                                                  .seaTileRemoval,
                                              parallelThreads:
                                                  (await SharedPreferences
                                                                  .getInstance())
                                                              .getBool(
                                                            'bypassDownloadThreadsLimitation',
                                                          ) ??
                                                          false
                                                      ? 10
                                                      : 2,
                                            ),
                                            disableRecovery: downloadProvider
                                                .disableRecovery,
                                          )
                                          .asBroadcastStream(),
                                    );

                                    if (mounted) Navigator.of(context).pop();
                                  },
                            child: const Text('Foreground'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: downloadProvider.selectedStore == null
                                ? null
                                : () async {
                                    final Map<String, String> metadata =
                                        await downloadProvider
                                            .selectedStore!.metadata.readAsync;

                                    await downloadProvider
                                        .selectedStore!.download
                                        .startBackground(
                                      region: widget.region.toDownloadable(
                                        downloadProvider.minZoom,
                                        downloadProvider.maxZoom,
                                        TileLayer(
                                          urlTemplate: metadata['sourceURL'],
                                        ),
                                        preventRedownload:
                                            downloadProvider.preventRedownload,
                                        seaTileRemoval:
                                            downloadProvider.seaTileRemoval,
                                        parallelThreads:
                                            (await SharedPreferences
                                                            .getInstance())
                                                        .getBool(
                                                      'bypassDownloadThreadsLimitation',
                                                    ) ??
                                                    false
                                                ? 10
                                                : 2,
                                      ),
                                      disableRecovery:
                                          downloadProvider.disableRecovery,
                                      backgroundNotificationIcon:
                                          const AndroidResource(
                                        name: 'ic_notification_icon',
                                        defType: 'mipmap',
                                      ),
                                    );

                                    if (mounted) Navigator.of(context).pop();
                                  },
                            child: const Text('Background'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
