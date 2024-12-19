import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/general_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';

void prepareDownloadConfigView(
  BuildContext context, {
  bool shouldShowConfig = true,
}) {
  final regionSelectionProvider = context.read<RegionSelectionProvider>();

  final bounds = LatLngBounds.fromPoints(
    regionSelectionProvider.constructedRegions.keys
        .elementAt(0)
        .toOutline()
        .toList(growable: false),
  );
  for (final region
      in regionSelectionProvider.constructedRegions.keys.skip(1)) {
    bounds.extendBounds(
      LatLngBounds.fromPoints(region.toOutline().toList(growable: false)),
    );
  }
  context.read<GeneralProvider>().animatedMapController.animatedFitCamera(
        cameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(16) +
              MediaQueryData.fromView(View.of(context)).padding +
              const EdgeInsets.only(bottom: 18),
        ),
      );

  if (shouldShowConfig) {
    regionSelectionProvider.isDownloadSetupPanelVisible = true;
  }
}
