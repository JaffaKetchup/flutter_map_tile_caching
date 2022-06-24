import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/state/download_provider.dart';
import 'components/region_information.dart';
import 'components/section_seperator.dart';

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
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              RegionInformation(
                widget: widget,
                circleRegion: circleRegion,
                rectangleRegion: rectangleRegion,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionSeperator(),
                  const Text('CHOOSE A STORE'),
                  Consumer<DownloadProvider>(
                    builder: (context, provider, _) =>
                        FutureBuilder<List<StoreDirectory>>(
                      future: FMTC
                          .instance.rootDirectory.stats.storesAvailableAsync,
                      builder: (context, snapshot) =>
                          DropdownButton<StoreDirectory>(
                        items: snapshot.data
                            ?.map(
                              (e) => DropdownMenuItem<StoreDirectory>(
                                value: e,
                                child: Text(e.storeName),
                              ),
                            )
                            .toList(),
                        onChanged: (store) => provider.selectedStore = store,
                        value: provider.selectedStore,
                        isExpanded: true,
                        hint: Text(
                          snapshot.data == null
                              ? 'Loading...'
                              : snapshot.data!.isEmpty
                                  ? 'None Available'
                                  : 'None Selected',
                        ),
                      ),
                    ),
                  ),
                  const SectionSeperator(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Start Foreground Download'),
                    ),
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: 'Request Enhanced Background Permissions',
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Icon(Icons.settings_suggest),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Start Background Download'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
