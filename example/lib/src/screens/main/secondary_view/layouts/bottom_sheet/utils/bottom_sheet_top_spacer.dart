import 'package:flutter/material.dart';

import '../bottom_sheet.dart';
import '../components/delayed_frame_attached_dependent_builder.dart';
import '../components/scrollable_provider.dart';

class BottomSheetTopSpacer extends StatelessWidget {
  const BottomSheetTopSpacer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenTopPadding =
        MediaQueryData.fromView(View.of(context)).padding.top;
    final outerScrollController =
        BottomSheetScrollableProvider.outerScrollControllerOf(context);

    return SliverToBoxAdapter(
      child: DelayedControllerAttachmentBuilder(
        listenable: outerScrollController,
        builder: (context, _) {
          if (!outerScrollController.isAttached) {
            return const SizedBox.shrink();
          }

          final maxHeight = outerScrollController.sizeToPixels(1);

          final oldValue = outerScrollController.pixels;
          final oldMax = maxHeight;
          final oldMin = maxHeight - screenTopPadding;

          const maxTopPadding = 0.0;
          const minTopPadding = SecondaryViewBottomSheet.topPadding - 8;

          final double topPaddingHeight =
              ((((oldValue - oldMin) * (maxTopPadding - minTopPadding)) /
                          (oldMax - oldMin)) +
                      minTopPadding)
                  .clamp(0.0, SecondaryViewBottomSheet.topPadding - 8);

          return SizedBox(height: topPaddingHeight);
        },
      ),
    );
  }
}
