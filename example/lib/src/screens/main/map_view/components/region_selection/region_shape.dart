import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';

class RegionShape extends StatelessWidget {
  const RegionShape({super.key});

  static const _fullWorldPolygon = [
    LatLng(-90, 180),
    LatLng(90, 180),
    LatLng(90, -180),
    LatLng(-90, -180),
  ];

  @override
  Widget build(BuildContext context) => Consumer<RegionSelectionProvider>(
        builder: (context, provider, _) => Stack(
          fit: StackFit.expand,
          children: [
            for (final MapEntry(key: region, value: color)
                in provider.constructedRegions.entries)
              switch (region) {
                RectangleRegion(:final bounds) => PolygonLayer(
                    polygons: [
                      Polygon(
                        points: [
                          bounds.northWest,
                          bounds.northEast,
                          bounds.southEast,
                          bounds.southWest,
                        ],
                        color: color.toColor().withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                CircleRegion(:final center, :final radius) => CircleLayer(
                    circles: [
                      CircleMarker(
                        point: center,
                        radius: radius * 1000,
                        useRadiusInMeter: true,
                        color: color.toColor().withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                LineRegion() => PolygonLayer(
                    polygons:
                        /* Polyline(
                        points: line,
                        strokeWidth: radius * 2,
                        useStrokeWidthInMeter: true,
                        color: color.toColor().withValues(alpha: 0.7),
                        strokeJoin: StrokeJoin.miter,
                        strokeCap: StrokeCap.square,
                      ),*/
                        region
                            .toOutlines(1)
                            .map(
                              (o) => Polygon(
                                points: o,
                                color: color.toColor().withValues(alpha: 0.7),
                              ),
                            )
                            .toList(growable: false),
                  ),
                CustomPolygonRegion(:final outline) => PolygonLayer(
                    polygons: [
                      Polygon(
                        points: outline,
                        color: color.toColor().withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                MultiRegion() => throw UnsupportedError(
                    'Cannot support `MultiRegion`s here',
                  ),
              },
            if (provider.currentConstructingCoordinates.isNotEmpty)
              if (provider.currentRegionType == RegionType.line)
                /* PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        ...provider.currentConstructingCoordinates,
                        provider.currentNewPointPos,
                      ],
                      color: Colors.white.withValues(alpha: 2 / 3),
                      strokeWidth: provider.lineRadius * 2,
                      strokeJoin: StrokeJoin.miter,
                      strokeCap: StrokeCap.square,
                      useStrokeWidthInMeter: true,
                    ),
                  ],
                )*/
                PolygonLayer(
                  polygons: LineRegion(
                    [
                      ...provider.currentConstructingCoordinates,
                      provider.currentNewPointPos,
                    ],
                    provider.lineRadius * 2,
                  )
                      .toOutlines(1)
                      .map(
                        (o) => Polygon(
                          points: o,
                          color: Colors.white.withValues(alpha: 2 / 3),
                        ),
                      )
                      .toList(growable: false),
                )
              else
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _fullWorldPolygon,
                      holePointsList: [
                        switch (provider.currentRegionType) {
                          RegionType.circle => CircleRegion(
                              provider.currentConstructingCoordinates[0],
                              const Distance(roundResult: false).distance(
                                    provider.currentConstructingCoordinates[0],
                                    provider.currentConstructingCoordinates
                                                .length ==
                                            1
                                        ? provider.currentNewPointPos
                                        : provider
                                            .currentConstructingCoordinates[1],
                                  ) /
                                  1000,
                            ).toOutline().toList(),
                          RegionType.rectangle => RectangleRegion(
                              LatLngBounds.fromPoints(
                                provider.currentConstructingCoordinates
                                            .length ==
                                        1
                                    ? [
                                        provider
                                            .currentConstructingCoordinates[0],
                                        provider.currentNewPointPos,
                                      ]
                                    : provider.currentConstructingCoordinates,
                              ),
                            ).toOutline().toList(),
                          RegionType.customPolygon => [
                              ...provider.currentConstructingCoordinates,
                              if (provider.customPolygonSnap)
                                provider.currentConstructingCoordinates.first
                              else
                                provider.currentNewPointPos,
                            ],
                          _ => throw UnsupportedError('Unreachable.'),
                        },
                      ],
                      borderColor: Colors.black,
                      borderStrokeWidth: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                    ),
                  ],
                ),
          ],
        ),
      );
}
