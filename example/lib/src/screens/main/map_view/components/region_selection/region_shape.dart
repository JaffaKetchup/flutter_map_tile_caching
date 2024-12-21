import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/state/general_provider.dart';
import '../../../../../shared/state/region_selection_provider.dart';

class RegionShape extends StatefulWidget {
  const RegionShape({super.key});

  @override
  State<RegionShape> createState() => _RegionShapeState();
}

class _RegionShapeState extends State<RegionShape> {
  @override
  Widget build(BuildContext context) => Consumer<RegionSelectionProvider>(
        builder: (context, provider, _) {
          final ccc = provider.currentConstructingCoordinates;
          final cnpp = provider.currentNewPointPos ??
              context
                  .watch<GeneralProvider>()
                  .animatedMapController
                  .mapController
                  .camera
                  .center;

          late final renderConstructingRegion = provider.currentRegionType ==
                  RegionType.line
              ? LineRegion([...ccc, cnpp], provider.lineRadius)
                  .toOutlines(1)
                  .toList(growable: false)
              : [
                  switch (provider.currentRegionType) {
                    RegionType.rectangle when ccc.length == 1 =>
                      RectangleRegion(LatLngBounds.fromPoints([ccc[0], cnpp]))
                          .toOutline()
                          .toList(),
                    RegionType.rectangle when ccc.length != 1 =>
                      RectangleRegion(LatLngBounds.fromPoints(ccc))
                          .toOutline()
                          .toList(),
                    RegionType.circle => CircleRegion(
                        ccc[0],
                        const Distance(roundResult: false).distance(
                              ccc[0],
                              ccc.length == 1 ? cnpp : ccc[1],
                            ) /
                            1000,
                      ).toOutline().toList(),
                    RegionType.customPolygon => [
                        ...ccc,
                        if (provider.customPolygonSnap) ccc.first else cnpp,
                      ],
                    _ => throw UnsupportedError('Unreachable.'),
                  },
                ];

          return Stack(
            fit: StackFit.expand,
            children: [
              for (final MapEntry(key: region, value: color)
                  in provider.constructedRegions.entries)
                _renderConstructedRegion(region, color),
              if (ccc.isNotEmpty) // Construction in progress
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: const [
                        LatLng(-90, 180),
                        LatLng(90, 180),
                        LatLng(90, -180),
                        LatLng(-90, -180),
                      ],
                      holePointsList: renderConstructingRegion,
                      borderColor: Colors.black,
                      borderStrokeWidth: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withAlpha(255 ~/ 2),
                    ),
                  ],
                ),
            ],
          );
        },
      );

  Widget _renderConstructedRegion(BaseRegion region, HSLColor color) {
    final isDownloading =
        context.watch<DownloadingProvider>().storeName != null;

    return switch (region) {
      RectangleRegion(:final bounds) => PolygonLayer(
          polygons: [
            Polygon(
              points: [
                bounds.northWest,
                bounds.northEast,
                bounds.southEast,
                bounds.southWest,
              ],
              color: isDownloading
                  ? Colors.transparent
                  : color.toColor().withAlpha(255 ~/ 2),
              borderColor: isDownloading ? Colors.black : Colors.transparent,
              borderStrokeWidth: 3,
            ),
          ],
        ),
      CircleRegion(:final center, :final radius) => CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radius * 1000,
              useRadiusInMeter: true,
              color: isDownloading
                  ? Colors.transparent
                  : color.toColor().withAlpha(255 ~/ 2),
              borderColor: isDownloading ? Colors.black : Colors.transparent,
              borderStrokeWidth: 3,
            ),
          ],
        ),
      LineRegion() => PolygonLayer(
          polygons: region
              .toOutlines(1)
              .map(
                (o) => Polygon(
                  points: o,
                  color: isDownloading
                      ? Colors.transparent
                      : color.toColor().withAlpha(255 ~/ 2),
                  borderColor:
                      isDownloading ? Colors.black : Colors.transparent,
                  borderStrokeWidth: 3,
                ),
              )
              .toList(growable: false),
        ),
      CustomPolygonRegion(:final outline) => PolygonLayer(
          polygons: [
            Polygon(
              points: outline,
              color: isDownloading
                  ? Colors.transparent
                  : color.toColor().withAlpha(255 ~/ 2),
              borderColor: isDownloading ? Colors.black : Colors.transparent,
              borderStrokeWidth: 3,
            ),
          ],
        ),
      MultiRegion() =>
        throw UnsupportedError('Cannot support `MultiRegion`s here'),
    };
  }
}
