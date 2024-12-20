import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/recoverable_regions_provider.dart';

class RecoveryRegions extends StatelessWidget {
  const RecoveryRegions({super.key});

  @override
  Widget build(BuildContext context) => Consumer<RecoverableRegionsProvider>(
        builder: (context, provider, _) {
          final map =
              <HSLColor, List<({List<List<LatLng>> pointss, String label})>>{};
          for (final MapEntry(key: region, value: color)
              in provider.failedRegions.entries) {
            (map[color] ??= []).add(
              (
                pointss: region.region.regions
                    .map((e) => e.toOutline().toList())
                    .toList(),
                label: "To '${region.storeName}'",
              ),
            );
          }

          return PolygonLayer(
            polygons: map.entries
                .map(
                  (e) => e.value
                      .map(
                        (region) => region.pointss.map(
                          (points) => Polygon(
                            points: points,
                            color: e.key.toColor().withAlpha(255 ~/ 2),
                            borderColor: e.key.toColor(),
                            borderStrokeWidth: 2,
                            label: region.label,
                            labelPlacement: PolygonLabelPlacement.polylabel,
                          ),
                        ),
                      )
                      .flattened,
                )
                .flattened
                .toList(),
          );
        },
      );
}
