import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../state/region_selection_provider.dart';

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
            height: 25,
            width: 25,
            point: coords.first,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1028),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, size: 15),
              ),
            ),
          ),
      ],
    );
  }
}
