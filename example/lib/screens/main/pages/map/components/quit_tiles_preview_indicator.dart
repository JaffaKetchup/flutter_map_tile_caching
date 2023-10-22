import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../downloading/state/downloading_provider.dart';
import 'side_indicator_painter.dart';

class QuitTilesPreviewIndicator extends StatelessWidget {
  const QuitTilesPreviewIndicator({
    super.key,
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 950;

    return Selector<DownloadingProvider, bool>(
      selector: (context, provider) => provider.showQuitTilesPreviewIndicator,
      builder: (context, sqtpi, child) => AnimatedPositioned(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.elasticOut,
        top: isNarrow ? null : constraints.maxHeight / 2 - 139,
        left: isNarrow
            ? constraints.maxWidth / 2 -
                55 -
                constraints.maxWidth / 4 -
                constraints.maxWidth / 8
            : sqtpi
                ? 8
                : -120,
        bottom: isNarrow
            ? sqtpi
                ? 38
                : -90
            : null,
        height: 50,
        width: 110,
        child: child!,
      ),
      child: Transform.rotate(
        angle: isNarrow ? 270 * pi / 180 : 0,
        child: CustomPaint(
          painter: SideIndicatorPainter(
            startRadius: const Radius.circular(8),
            endRadius: const Radius.circular(25),
            color: Theme.of(context).colorScheme.background,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: isNarrow ? 1 : 0,
                  child: const Icon(Icons.touch_app, size: 32),
                ),
                const SizedBox.square(dimension: 6),
                RotatedBox(
                  quarterTurns: isNarrow ? 1 : 0,
                  child: const Icon(Icons.visibility_off, size: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
