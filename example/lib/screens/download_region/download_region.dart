import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/state/download_provider.dart';
import '../../shared/state/general_provider.dart';
import 'components/background_download_info.dart';
import 'components/optional_functionality.dart';
import 'components/region_information.dart';
import 'components/section_seperator.dart';
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
                  const SectionSeperator(),
                  const StoreSelector(),
                  const SectionSeperator(),
                  const OptionalFunctionality(),
                  const SectionSeperator(),
                  const BackgroundDownloadInfo(),
                  const SectionSeperator(),
                  const UsageWarning(),
                  const SectionSeperator(),
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

                                    downloadProvider.downloadProgress =
                                        downloadProvider.selectedStore!.download
                                            .startForeground(
                                              region:
                                                  widget.region.toDownloadable(
                                                downloadProvider.minZoom,
                                                downloadProvider.maxZoom,
                                                TileLayerOptions(
                                                  urlTemplate:
                                                      metadata['sourceURL'],
                                                ),
                                                preventRedownload:
                                                    downloadProvider
                                                        .preventRedownload,
                                                seaTileRemoval: downloadProvider
                                                    .seaTileRemoval,
                                              ),
                                              disableRecovery: downloadProvider
                                                  .disableRecovery,
                                            )
                                            .asBroadcastStream();

                                    /*downloadProvider.downloadProgress!.listen(
                                      (evt) => print(evt.percentageProgress),
                                    );*/

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
                                : () {},
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
