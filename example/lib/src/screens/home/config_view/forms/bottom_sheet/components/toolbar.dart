import 'package:flutter/material.dart';

import '../bottom_sheet.dart';

class BottomSheetToolbar extends StatelessWidget {
  const BottomSheetToolbar({
    super.key,
    required this.bottomSheetOuterController,
    required this.action,
  });

  final DraggableScrollableController bottomSheetOuterController;
  final Widget action;

  double _calcVisibility(double size, double newMax) =>
      ((((size - 0.3) * (newMax - 0)) / (0.85 - 0.3)) + 0).clamp(0, newMax);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AnimatedBuilder(
            animation: bottomSheetOuterController,
            builder: (context, child) => SizedBox(
              height: ConfigViewBottomSheet.topPadding -
                  _calcVisibility(bottomSheetOuterController.size, 16),
            ),
          ),
          AnimatedBuilder(
            animation: bottomSheetOuterController,
            builder: (context, child) {
              final size = bottomSheetOuterController.size;

              return Padding(
                padding: EdgeInsets.only(bottom: _calcVisibility(size, 8)),
                child: Opacity(
                  opacity: _calcVisibility(size, 1),
                  child: SizedBox(
                    height: _calcVisibility(size, 50),
                    child: child,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                action,
              ],
            ),
          ),
        ],
      );
}
