import 'package:flutter/material.dart';
import '../../secondary_view/layouts/bottom_sheet/components/delayed_frame_attached_dependent_builder.dart';

import '../map_view.dart';

/// Wraps [MapView] with the necessary widgets to keep the map contents clear
/// of the bottom sheet
///
/// Not suitable for use with screens wider than the max width of the bottom
/// sheet, nor where there is no bottom sheet in use.
class BottomSheetMapWrapper extends StatefulWidget {
  const BottomSheetMapWrapper({
    super.key,
    required this.bottomSheetOuterController,
    this.mode = MapViewMode.standard,
    required this.layoutDirection,
  });

  final DraggableScrollableController bottomSheetOuterController;
  final MapViewMode mode;
  final Axis layoutDirection;

  @override
  State<BottomSheetMapWrapper> createState() => _BottomSheetMapWrapperState();
}

class _BottomSheetMapWrapperState extends State<BottomSheetMapWrapper> {
  // Extend the map as little as possible overlapping the bottom sheet to ensure
  // the background does not appear outside the bottom sheet radius but also
  // to load as little extra tiles as possible.
  static const _assumedBottomSheetCornerRadius = 18;

  @override
  Widget build(BuildContext context) {
    // Introduce padding at the top of the screen to ensure the map gets
    // below the status bar/front-camera.
    // Introduce padding at the bottom of the screen to ensure that the
    // center of the map is affected by the bottom sheet, so the center
    // is always in the 'visible' center.
    final screenPaddingTop =
        MediaQueryData.fromView(View.of(context)).padding.top;

    return DelayedControllerAttachmentBuilder(
      listenable: widget.bottomSheetOuterController,
      builder: (context, child) {
        final isAttached = widget.bottomSheetOuterController.isAttached;

        return Padding(
          padding: EdgeInsets.only(
            bottom: isAttached
                ? (widget.bottomSheetOuterController.pixels -
                        _assumedBottomSheetCornerRadius)
                    .clamp(0, double.nan)
                : 200,
            top: screenPaddingTop,
          ),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Allow the map to overflow, so the center remains at the
          // ('visible') center, but everything else is drawn over the
          // padding we just introduced, to give a seamless effect without
          // black background at the top behind the status bar.
          //
          // Technically, overflowing downwards isn't necessary, but we
          // must to ensure the center remains at the 'visible' center.
          final height = constraints.maxHeight + screenPaddingTop * 2;

          return OverflowBox(
            maxHeight: height,
            child: MapView(
              mode: widget.mode,
              layoutDirection: widget.layoutDirection,
              bottomSheetOuterController: widget.bottomSheetOuterController,
              bottomPaddingWrapperBuilder: (context, child) {
                final useAssumedRadius =
                    !widget.bottomSheetOuterController.isAttached ||
                        widget.bottomSheetOuterController.pixels >
                            _assumedBottomSheetCornerRadius;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: screenPaddingTop +
                        (useAssumedRadius
                            ? _assumedBottomSheetCornerRadius
                            : widget.bottomSheetOuterController.pixels),
                  ),
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
