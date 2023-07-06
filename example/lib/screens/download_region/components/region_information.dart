import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';

class RegionInformation extends StatelessWidget {
  const RegionInformation({
    super.key,
    required this.region,
  });

  final BaseRegion region;

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
                  ...region.when(
                    rectangle: (rectangle) => [
                      const Text('APPROX. NORTH WEST'),
                      Text(
                        '${rectangle.bounds.northWest.latitude.toStringAsFixed(3)}, ${rectangle.bounds.northWest.longitude.toStringAsFixed(3)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('APPROX. SOUTH EAST'),
                      Text(
                        '${rectangle.bounds.southEast.latitude.toStringAsFixed(3)}, ${rectangle.bounds.southEast.longitude.toStringAsFixed(3)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                    circle: (circle) => [
                      const Text('APPROX. CENTER'),
                      Text(
                        '${circle.center.latitude.toStringAsFixed(3)}, ${circle.center.longitude.toStringAsFixed(3)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('RADIUS'),
                      Text(
                        '${circle.radius.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                    line: (line) {
                      const distCalc = Distance(roundResult: false);
                      double totalDistance = 0;
                      for (int i = 0; i < line.line.length - 1; i++) {
                        totalDistance +=
                            distCalc.distance(line.line[i], line.line[i + 1]);
                      }

                      return [
                        const Text('LINE LENGTH'),
                        Text(
                          '${(totalDistance / 1000).toStringAsFixed(3)} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('FIRST COORD'),
                        Text(
                          '${line.line[0].latitude.toStringAsFixed(3)}, ${line.line[0].longitude.toStringAsFixed(3)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('LAST COORD'),
                        Text(
                          '${line.line.last.latitude.toStringAsFixed(3)}, ${line.line.last.longitude.toStringAsFixed(3)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ];
                    },
                  ),
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
