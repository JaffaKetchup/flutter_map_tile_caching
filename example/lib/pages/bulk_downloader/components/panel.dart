import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:fmtc_example/pages/bulk_downloader/components/region_mode.dart';
import 'package:fmtc_example/state/general_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'constraints.dart';
import 'stat_builder.dart';
import 'xy_to_latlng.dart';

class Panel extends StatelessWidget {
  const Panel({
    Key? key,
    required this.mcm,
    required this.controller,
    required this.constraints,
    required this.regionTypeIndex,
    required this.regionTypeChangedCallback,
  }) : super(key: key);

  final MapCachingManager mcm;
  final MapController controller;
  final Constraints? constraints;
  final int regionTypeIndex;
  final void Function(int) regionTypeChangedCallback;

  RegionMode get regionMode => RegionMode.values[regionTypeIndex];

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        final String? source =
            provider.persistent!.getString('${mcm.storeName}: sourceURL');

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          height: 150,
          child: SafeArea(
            child: Center(
              child: Column(
                children: [
                  Flexible(
                    child: ListView.separated(
                      itemCount: RegionMode.values.length,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ChoiceChip(
                          label: Text(RegionMode.values[index].name),
                          selected: regionTypeIndex == index,
                          onSelected: (_) => regionTypeChangedCallback(index),
                        );
                      },
                      separatorBuilder: (context, _) =>
                          const SizedBox(width: 10),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<MapEvent>(
                      stream: controller.mapEventStream
                          .debounce(const Duration(milliseconds: 500)),
                      builder: (context, evt) {
                        if (!evt.hasData ||
                            evt.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 10),
                                Text('Awaiting Map Event...'),
                              ],
                            ),
                          );
                        }

                        return FutureBuilder<List<LatLng?>>(
                          future: Future.wait(
                            regionMode == RegionMode.Circle
                                ? [
                                    xyToLatLng(
                                      context: context,
                                      controller: controller,
                                      offset: constraints?.middleCenter ??
                                          Offset.zero,
                                    ),
                                    xyToLatLng(
                                      context: context,
                                      controller: controller,
                                      offset: constraints?.edgeCenter ??
                                          Offset.zero,
                                    ),
                                  ]
                                : [
                                    xyToLatLng(
                                      context: context,
                                      controller: controller,
                                      offset:
                                          constraints?.topLeft ?? Offset.zero,
                                    ),
                                    xyToLatLng(
                                      context: context,
                                      controller: controller,
                                      offset: constraints?.bottomRight ??
                                          Offset.zero,
                                    ),
                                  ],
                          ),
                          builder: (context, xy) {
                            if (!xy.hasData ||
                                xy.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: Column(
                                  children: const [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text('Calculating Lat/Lng Values...'),
                                  ],
                                ),
                              );
                            }

                            final DownloadableRegion region =
                                (regionMode == RegionMode.Circle
                                        ? CircleRegion(
                                            xy.data![0]!,
                                            const Distance().distance(
                                                    xy.data![0]!,
                                                    xy.data![1]!) /
                                                1000,
                                          )
                                        : RectangleRegion(
                                            LatLngBounds(
                                              xy.data![0],
                                              xy.data![1],
                                            ),
                                          ))
                                    .toDownloadable(
                              1,
                              18,
                              TileLayerOptions(urlTemplate: source),
                            );

                            return FutureBuilder<int>(
                              future: StorageCachingTileProvider.checkRegion(
                                  region),
                              builder: (context, tiles) {
                                if (!tiles.hasData ||
                                    tiles.connectionState ==
                                        ConnectionState.waiting) {
                                  return Center(
                                    child: Column(
                                      children: const [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 10),
                                        Text('Counting Tiles...'),
                                      ],
                                    ),
                                  );
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    statBuilder(
                                      stat: tiles.data!.toString(),
                                      description: 'est. tiles',
                                    ),
                                    const SizedBox(width: 30),
                                    tiles.data! > 50000
                                        ? Container(
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Area too large!\nSelect a region under 50000 tiles',
                                                style: TextStyle(
                                                    color: Colors.white),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final Stream<DownloadProgress>
                                                      progress =
                                                      StorageCachingTileProvider(
                                                    parentDirectory:
                                                        await MapCachingManager
                                                            .normalCache,
                                                    storeName: mcm.storeName,
                                                  ).downloadRegion(
                                                    region,
                                                    preDownloadChecksCallback:
                                                        null,
                                                  );

                                                  progress.listen(
                                                    (event) {
                                                      print(event
                                                              .percentageProgress
                                                              .toStringAsFixed(
                                                                  3) +
                                                          '%');
                                                    },
                                                  );
                                                },
                                                child:
                                                    const Icon(Icons.download),
                                                style: ButtonStyle(
                                                  shape:
                                                      MaterialStateProperty.all(
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topRight: Radius.zero,
                                                        topLeft:
                                                            Radius.circular(30),
                                                        bottomLeft:
                                                            Radius.circular(30),
                                                        bottomRight:
                                                            Radius.zero,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              OutlinedButton(
                                                onPressed: () {},
                                                child:
                                                    const Text('In Background'),
                                                style: ButtonStyle(
                                                  shape:
                                                      MaterialStateProperty.all(
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft: Radius.zero,
                                                        topRight:
                                                            Radius.circular(30),
                                                        bottomRight:
                                                            Radius.circular(30),
                                                        bottomLeft: Radius.zero,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
