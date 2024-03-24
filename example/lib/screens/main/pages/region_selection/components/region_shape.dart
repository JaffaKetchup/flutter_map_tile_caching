import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/region_type.dart';
import '../state/region_selection_provider.dart';

class RegionShape extends StatelessWidget {
  const RegionShape({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Consumer<RegionSelectionProvider>(
        builder: (context, provider, _) {
          if (provider.regionType == RegionType.line) {
            if (provider.coordinates.isEmpty) return const SizedBox.shrink();
            return PolylineLayer(
              polylines: [
                Polyline(
                  points: [
                    ...provider.coordinates,
                    provider.currentNewPointPos,
                  ],
                  borderColor: Colors.black,
                  borderStrokeWidth: 2,
                  color: Colors.green.withOpacity(2 / 3),
                  strokeWidth: provider.lineRadius * 2,
                  useStrokeWidthInMeter: true,
                ),
              ],
            );
          }

          final List<LatLng> holePoints;
          if (provider.coordinates.isEmpty) {
            holePoints = [];
          } else {
            switch (provider.regionType) {
              case RegionType.square:
                final bounds = LatLngBounds.fromPoints(
                  provider.coordinates.length == 1
                      ? [provider.coordinates[0], provider.currentNewPointPos]
                      : provider.coordinates,
                );
                holePoints = [
                  bounds.northWest,
                  bounds.northEast,
                  bounds.southEast,
                  bounds.southWest,
                ];
              case RegionType.circle:
                holePoints = CircleRegion(
                  provider.coordinates[0],
                  const Distance(roundResult: false).distance(
                        provider.coordinates[0],
                        provider.coordinates.length == 1
                            ? provider.currentNewPointPos
                            : provider.coordinates[1],
                      ) /
                      1000,
                ).toOutline().toList();
              case RegionType.line:
                throw Error();
              case RegionType.customPolygon:
                holePoints = provider.isCustomPolygonComplete
                    ? provider.coordinates
                    : [
                        ...provider.coordinates,
                        if (provider.customPolygonSnap)
                          provider.coordinates.first
                        else
                          provider.currentNewPointPos,
                      ];
            }
          }

          return PolygonLayer(
            polygons: [
              Polygon(
                points: [
                  const LatLng(-90, 180),
                  const LatLng(90, 180),
                  const LatLng(90, -180),
                  const LatLng(-90, -180),
                ],
                holePointsList: [holePoints],
                isFilled: true,
                borderColor: Colors.black,
                borderStrokeWidth: 2,
                color:
                    Theme.of(context).colorScheme.background.withOpacity(0.5),
              ),
            ],
          );
        },
      );
}
