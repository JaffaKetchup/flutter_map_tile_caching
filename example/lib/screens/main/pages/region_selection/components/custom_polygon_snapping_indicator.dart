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
  Widget build(BuildContext context) => MarkerLayer(
        markers: [
          if (context
                  .select<RegionSelectionProvider, List<LatLng>>(
                    (p) => p.coordinates,
                  )
                  .isNotEmpty &&
              context.select<RegionSelectionProvider, bool>(
                (p) => p.customPolygonSnap,
              ))
            Marker(
              height: 25,
              width: 25,
              point: context
                  .select<RegionSelectionProvider, List<LatLng>>(
                    (p) => p.coordinates,
                  )
                  .first,
              builder: (context) => DecoratedBox(
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
