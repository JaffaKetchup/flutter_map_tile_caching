import 'package:flutter/material.dart' hide BottomSheet;

import '../../../../../../../shared/components/delayed_frame_attached_dependent_builder.dart';
import '../../../../map_config.dart';
import '../../bottom_sheet.dart';
import '../../components/scrollable_provider.dart';
import 'components/tab_header.dart';

class StoresAndConfigureTab extends StatefulWidget {
  const StoresAndConfigureTab({
    super.key,
    required this.bottomSheetOuterController,
  });

  final DraggableScrollableController bottomSheetOuterController;

  @override
  State<StoresAndConfigureTab> createState() => _StoresAndConfigureTabState();
}

class _StoresAndConfigureTabState extends State<StoresAndConfigureTab> {
  final urlTextController = TextEditingController(
    text: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  @override
  Widget build(BuildContext context) {
    final screenTopPadding =
        MediaQueryData.fromView(View.of(context)).padding.top;

    return MapConfig(
      controller:
          BottomSheetScrollableProvider.innerScrollControllerOf(context),
      leading: [
        SliverToBoxAdapter(
          child: DelayedControllerAttachmentBuilder(
            listenable: widget.bottomSheetOuterController,
            builder: (context, _) {
              if (!widget.bottomSheetOuterController.isAttached) {
                return const SizedBox.shrink();
              }

              final maxHeight =
                  widget.bottomSheetOuterController.sizeToPixels(1);

              final oldValue = widget.bottomSheetOuterController.pixels;
              final oldMax = maxHeight;
              final oldMin = maxHeight - screenTopPadding;

              const maxTopPadding = 0.0;
              const minTopPadding = BottomSheet.topPadding - 8;

              final double topPaddingHeight =
                  ((((oldValue - oldMin) * (maxTopPadding - minTopPadding)) /
                              (oldMax - oldMin)) +
                          minTopPadding)
                      .clamp(0.0, BottomSheet.topPadding - 8);

              return SizedBox(height: topPaddingHeight);
            },
          ),
        ),
        TabHeader(
          bottomSheetOuterController: widget.bottomSheetOuterController,
        ),
      ],
    );
  }
}
