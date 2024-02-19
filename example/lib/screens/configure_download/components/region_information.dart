import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_earcut/dart_earcut.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class RegionInformation extends StatefulWidget {
  const RegionInformation({
    super.key,
    required this.region,
    required this.minZoom,
    required this.maxZoom,
  });

  final BaseRegion region;
  final int minZoom;
  final int maxZoom;

  @override
  State<RegionInformation> createState() => _RegionInformationState();
}

class _RegionInformationState extends State<RegionInformation> {
  final distance = const Distance(roundResult: false).distance;

  late Future<int> numOfTiles;

  @override
  void initState() {
    super.initState();
    numOfTiles = const FMTCStore('').download.check(
          widget.region.toDownloadable(
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            options: TileLayer(),
          ),
        );
  }

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
                  ...widget.region.when(
                    rectangle: (rectangle) => [
                      const Text('TOTAL AREA'),
                      Text(
                        '${(distance(rectangle.bounds.northWest, rectangle.bounds.northEast) * distance(rectangle.bounds.northEast, rectangle.bounds.southEast) / 1000000).toStringAsFixed(3)} km²',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const Text('TOTAL AREA'),
                      Text(
                        '${(pi * pow(circle.radius, 2)).toStringAsFixed(3)} km²',
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
                      const SizedBox(height: 10),
                      const Text('APPROX. CENTER'),
                      Text(
                        '${circle.center.latitude.toStringAsFixed(3)}, ${circle.center.longitude.toStringAsFixed(3)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                    line: (line) {
                      double totalDistance = 0;

                      for (int i = 0; i < line.line.length - 1; i++) {
                        totalDistance +=
                            distance(line.line[i], line.line[i + 1]);
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
                    customPolygon: (customPolygon) {
                      double area = 0;

                      for (final triangle in Earcut.triangulateFromPoints(
                        customPolygon.outline
                            .map(const Epsg3857().projection.project),
                      ).map(customPolygon.outline.elementAt).slices(3)) {
                        final a = distance(triangle[0], triangle[1]);
                        final b = distance(triangle[1], triangle[2]);
                        final c = distance(triangle[2], triangle[0]);

                        area += 0.25 *
                            sqrt(
                              4 * a * a * b * b - pow(a * a + b * b - c * c, 2),
                            );
                      }

                      return [
                        const Text('TOTAL AREA'),
                        Text(
                          '${(area / 1000000).toStringAsFixed(3)} km²',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MIN/MAX ZOOM LEVELS'),
                  Text(
                    '${widget.minZoom} - ${widget.maxZoom}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('TOTAL TILES'),
                  FutureBuilder<int>(
                    future: numOfTiles,
                    builder: (context, snapshot) => snapshot.data == null
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
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            NumberFormat('###,###').format(snapshot.data),
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
