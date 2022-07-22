import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';
import '../download_region.dart';

class RegionInformation extends StatelessWidget {
  const RegionInformation({
    Key? key,
    required this.widget,
    required this.circleRegion,
    required this.rectangleRegion,
  }) : super(key: key);

  final DownloadRegionPopup widget;
  final CircleRegion? circleRegion;
  final RectangleRegion? rectangleRegion;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.region is CircleRegion) ...[
                    const Text('APPROX. CENTER'),
                    Text(
                      '${circleRegion!.center.latitude.toStringAsFixed(3)}, ${circleRegion!.center.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('RADIUS'),
                    Text(
                      '${circleRegion!.radius.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ] else ...[
                    const Text('APPROX. NORTH WEST'),
                    Text(
                      '${rectangleRegion!.bounds.northWest.latitude.toStringAsFixed(3)}, ${rectangleRegion!.bounds.northWest.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('APPROX. SOUTH EAST'),
                    Text(
                      '${rectangleRegion!.bounds.southEast.latitude.toStringAsFixed(3)}, ${rectangleRegion!.bounds.southEast.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text('MIN/MAX ZOOM LEVELS'),
                  Consumer<DownloadProvider>(
                    builder: (context, provider, _) =>
                        provider.regionTiles == null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: Center(
                                    child: SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                '${provider.minZoom} - ${provider.maxZoom}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL TILES'),
                  Consumer<DownloadProvider>(
                    builder: (context, provider, _) =>
                        provider.regionTiles == null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: Center(
                                    child: SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                NumberFormat('###,###')
                                    .format(provider.regionTiles),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}
