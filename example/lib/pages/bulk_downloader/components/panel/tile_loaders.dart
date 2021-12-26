import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../state/bulk_download_provider.dart';
import '../region_mode.dart';
import '../xy_to_latlng.dart';

class TileLoader extends StatefulWidget {
  const TileLoader({
    Key? key,
    required this.mcm,
    required this.controller,
    required this.mapSource,
  }) : super(key: key);

  final MapCachingManager mcm;
  final MapController controller;
  final String? mapSource;

  @override
  State<TileLoader> createState() => _TileLoaderState();
}

class _TileLoaderState extends State<TileLoader> {
  late Future<List<LatLng>> tileCountFuture;
  late Future<List<LatLng>> uiConfirmationFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final BulkDownloadProvider bdp = Provider.of<BulkDownloadProvider>(context);

    final bool isCircle = bdp.mode == RegionMode.Circle;
    const Offset offset = Offset(0, 60);
    final double height = bdp.region?.screenConstraints.maxHeight ?? 0;
    final double width = bdp.region?.screenConstraints.maxWidth ?? 0;

    tileCountFuture = Future.wait(
      [
        xyToLatLng(
          controller: widget.controller,
          offset:
              ((isCircle ? bdp.region?.middleCenter : bdp.region?.topLeft) ??
                      Offset.zero) -
                  offset,
          height: height,
          width: width,
        ),
        xyToLatLng(
          controller: widget.controller,
          offset:
              ((isCircle ? bdp.region?.edgeCenter : bdp.region?.bottomRight) ??
                      Offset.zero) -
                  offset,
          height: height,
          width: width,
        ),
      ],
    );

    uiConfirmationFuture = Future.wait(
      [
        xyToLatLng(
          controller: widget.controller,
          offset: (bdp.region?.middleCenter ?? Offset.zero) - offset,
          height: height,
          width: width,
        ),
        xyToLatLng(
          controller: widget.controller,
          offset: (bdp.region?.topLeft ?? Offset.zero) - offset,
          height: height,
          width: width,
        ),
      ],
    );

    /*(() async {
      await widget.controller.onReady;
    }());*/
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BulkDownloadProvider, RegionMode>(
      selector: (_, bdp) => bdp.mode,
      builder: (context, mode, _) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
          ),
          borderRadius: BorderRadius.circular(58),
        ),
        padding: const EdgeInsets.only(left: 16),
        child: FutureBuilder<List<LatLng>>(
          future: uiConfirmationFuture,
          builder: (context, ui) {
            /*if (!ui.hasData ||
                    ui.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Calculating Lat/Lng Values (1)...'),
                      ],
                    ),
                  );
                }*/

            if (ui.hasData) {
              WidgetsBinding.instance!.addPostFrameCallback((_) {
                //bdp.centerAndEdge = ui.data!;
                //Provider.of<BulkDownloadProvider>(context, listen: false)
                //    .centerAndEdge = ui.data!;
              });
            }

            return FutureBuilder<List<LatLng>>(
              future: tileCountFuture,
              builder: (context, xy) {
                if (!xy.hasData ||
                    xy.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Calculating Lat/Lng Values (2)...'),
                      ],
                    ),
                  );
                }

                final DownloadableRegion region = (mode == RegionMode.Circle
                        ? CircleRegion(
                            xy.data![0],
                            const Distance()
                                    .distance(xy.data![0], xy.data![1]) /
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
                  16,
                  TileLayerOptions(
                    urlTemplate: widget.mapSource,
                    subdomains: [
                      'a',
                      'b',
                      'c',
                    ],
                  ),
                );

                return TileLoader2(
                  region: region,
                  mcm: widget.mcm,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class TileLoader2 extends StatefulWidget {
  const TileLoader2({
    Key? key,
    required this.mcm,
    required this.region,
  }) : super(key: key);

  final MapCachingManager mcm;
  final DownloadableRegion region;

  @override
  _TileLoader2State createState() => _TileLoader2State();
}

class _TileLoader2State extends State<TileLoader2> {
  late Future<int> future;

  @override
  void initState() {
    super.initState();
    future = StorageCachingTileProvider.checkRegion(widget.region);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, tiles) {
        if (!tiles.hasData ||
            tiles.connectionState == ConnectionState.waiting) {
          return Center(
            child: Row(
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Counting Tiles...'),
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
            ElevatedButton.icon(
              onPressed: () {
                final Stream<DownloadProgress> download =
                    StorageCachingTileProvider.fromMapCachingManager(widget.mcm)
                        .downloadRegion(
                  widget.region,
                  preDownloadChecksCallback: (_, __, ___) async => null,
                );

                download.listen((event) {
                  print(
                    event.percentageProgress.toStringAsFixed(2) +
                        '% complete - ' +
                        event.remainingTiles.toString() +
                        ' tiles remaining',
                  );
                });
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
