import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/general_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';

class SubRegionsList extends StatefulWidget {
  const SubRegionsList({super.key});

  @override
  State<SubRegionsList> createState() => _SubRegionsListState();
}

class _SubRegionsListState extends State<SubRegionsList> {
  @override
  Widget build(BuildContext context) {
    final constructedRegions =
        context.select<RegionSelectionProvider, Map<BaseRegion, HSLColor>>(
      (p) => p.constructedRegions,
    );

    return SliverList.builder(
      itemCount: constructedRegions.length,
      itemBuilder: (context, index) {
        final region = constructedRegions.keys.elementAt(index);
        final color = constructedRegions.values.elementAt(index).toColor();

        return ListTile(
          leading: switch (region) {
            RectangleRegion() => Icon(Icons.rectangle, color: color),
            CircleRegion() => Icon(Icons.circle, color: color),
            LineRegion() => Icon(Icons.polyline, color: color),
            CustomPolygonRegion() => Icon(Icons.pentagon, color: color),
            _ => throw UnsupportedError('Cannot support `MultiRegion`s here'),
          },
          title: switch (region) {
            RectangleRegion() => const Text('Rectangle Region'),
            CircleRegion() => const Text('Circle Region'),
            LineRegion() => const Text('Line Region'),
            CustomPolygonRegion() => const Text('Custom Polygon Region'),
            _ => throw UnsupportedError('Cannot support `MultiRegion`s here'),
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  context
                      .read<GeneralProvider>()
                      .animatedMapController
                      .animatedFitCamera(
                        cameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(
                            region.toOutline().toList(),
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      );
                },
                icon: const Icon(Icons.filter_center_focus),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  context
                      .read<RegionSelectionProvider>()
                      .removeConstructedRegion(region);
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        );
      },
    );
  }
}
