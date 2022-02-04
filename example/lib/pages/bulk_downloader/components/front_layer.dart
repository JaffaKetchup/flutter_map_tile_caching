import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../bulk_downloader.dart';

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
    widget.rdtc.listen(
      (e) => setState(() {
        streamEvt = e;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
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

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tiles.data!.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const Text('est. tiles'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ((tiles.data! * 20) / 1024).toStringAsFixed(2) +
                                'MiB',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const Text('est. avg. storage'),
                        ],
                      ),
                      //Expanded(child: Text(coords.data.toString())),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
