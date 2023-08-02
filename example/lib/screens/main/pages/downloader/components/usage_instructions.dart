import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/region_selection_method.dart';
import '../../../../../shared/misc/region_type.dart';
import '../../../../../shared/state/download_provider.dart';

class UsageInstructions extends StatelessWidget {
  UsageInstructions({
    super.key,
    required this.constraints,
  }) : layoutDirection =
            constraints.maxWidth > 1325 ? Axis.vertical : Axis.horizontal;

  final BoxConstraints constraints;
  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => PositionedDirectional(
        top: layoutDirection == Axis.vertical ? 0 : 24,
        bottom: layoutDirection == Axis.vertical ? 0 : null,
        start: layoutDirection == Axis.vertical ? null : 0,
        end: layoutDirection == Axis.vertical ? 164 : 0,
        child: UnconstrainedBox(
          child: Consumer<DownloaderProvider>(
            builder: (context, provider, _) => AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              opacity: provider.coordinates.isEmpty ? 1 : 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(1 / 3),
                        spreadRadius: 50,
                        blurRadius: 90,
                      ),
                    ],
                  ),
                  child: Flex(
                    direction: layoutDirection,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (layoutDirection == Axis.vertical)
                        const Icon(Icons.touch_app, size: 68),
                      if (layoutDirection == Axis.vertical)
                        const SizedBox.square(dimension: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tap/click to add ${provider.regionType == RegionType.circle ? 'center' : 'point'} at ${provider.regionSelectionMethod == RegionSelectionMethod.useMapCenter ? 'map center' : 'pointer'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          provider.regionType == RegionType.circle
                              ? const Text(
                                  'Tap/click again to set radius',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Long press/right click to remove last point',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ],
                      ),
                      if (layoutDirection == Axis.horizontal)
                        const SizedBox.square(dimension: 12),
                      if (layoutDirection == Axis.horizontal)
                        const Icon(Icons.touch_app, size: 68),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
