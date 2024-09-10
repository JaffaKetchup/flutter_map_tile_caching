import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';

class CustomPolygonSnappingIndicator extends StatelessWidget {
  const CustomPolygonSnappingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final coords = context
        .select<RegionSelectionProvider, List<LatLng>>((p) => p.coordinates);

    return MarkerLayer(
      markers: [
        if (coords.isNotEmpty &&
            context.select<RegionSelectionProvider, bool>(
              (p) => p.customPolygonSnap,
            ))
          Marker(
            height: 32,
            width: 32,
            point: coords.first,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_fix_normal,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
