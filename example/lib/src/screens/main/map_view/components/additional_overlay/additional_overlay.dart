import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';
import '../../../secondary_view/contents/region_selection/components/shape_selector/shape_selector.dart';
import '../../../secondary_view/layouts/bottom_sheet/components/delayed_frame_attached_dependent_builder.dart';
import '../../map_view.dart';
import 'fmtc_not_in_use_indicator.dart';

class AdditionalOverlay extends StatelessWidget {
  const AdditionalOverlay({
    super.key,
    required this.bottomSheetOuterController,
    required this.layoutDirection,
    required this.mode,
  });

  final DraggableScrollableController bottomSheetOuterController;
  final Axis layoutDirection;
  final MapViewMode mode;

  @override
  Widget build(BuildContext context) {
    final showShapeSelector = mode == MapViewMode.downloadRegion &&
        !context.read<RegionSelectionProvider>().isDownloadSetupPanelVisible;

    return AnimatedSlide(
      offset: mode != MapViewMode.standard ? Offset.zero : const Offset(0, 1.1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FMTCNotInUseIndicator(mode: mode),
          ),
          if (layoutDirection == Axis.vertical)
            SizedBox(
              width: double.infinity,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: DelayedControllerAttachmentBuilder(
                  listenable: bottomSheetOuterController,
                  builder: (context, child) {
                    if (!bottomSheetOuterController.isAttached) return child!;
                    return AnimatedBuilder(
                      animation: bottomSheetOuterController,
                      builder: (context, child) => _HeightZero(
                        useChildHeight: showShapeSelector &&
                            bottomSheetOuterController.pixels <= 33,
                        child: child!,
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    margin: EdgeInsets.only(
                      bottom: 8 +
                          (context
                                  .watch<RegionSelectionProvider>()
                                  .constructedRegions
                                  .isNotEmpty
                              ? 40
                              : 0),
                    ),
                    child: const ShapeSelector(),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _HeightZeroRenderer extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin<RenderBox> {
  _HeightZeroRenderer({required bool useChildHeight})
      : _useChildHeight = useChildHeight;

  bool get useChildHeight => _useChildHeight;
  bool _useChildHeight;
  set useChildHeight(bool value) {
    if (_useChildHeight != value) {
      _useChildHeight = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    size = Size(
      child!.size.width,
      useChildHeight ? child!.size.height : 0,
    );
  }
}

class _HeightZero extends SingleChildRenderObjectWidget {
  const _HeightZero({
    this.useChildHeight = false,
    required Widget super.child,
  });

  final bool useChildHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _HeightZeroRenderer(useChildHeight: useChildHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _HeightZeroRenderer renderObject,
  ) =>
      renderObject.useChildHeight = useChildHeight;
}
