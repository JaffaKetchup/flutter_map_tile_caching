import 'package:flutter/material.dart';

import '../../../../../shared/components/delayed_frame_attached_dependent_builder.dart';
import '../../layouts/bottom_sheet/bottom_sheet.dart';
import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/components/tab_header.dart';
import 'components/map/map.dart';
import 'components/stores/stores_list.dart';

class HomeViewBottomSheet extends StatefulWidget {
  const HomeViewBottomSheet({
    super.key,
    required this.bottomSheetOuterController,
  });

  final DraggableScrollableController bottomSheetOuterController;

  @override
  State<HomeViewBottomSheet> createState() => _ContentPanelsState();
}

class _ContentPanelsState extends State<HomeViewBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final screenTopPadding =
        MediaQueryData.fromView(View.of(context)).padding.top;

    return CustomScrollView(
      controller:
          BottomSheetScrollableProvider.innerScrollControllerOf(context),
      slivers: [
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
              const minTopPadding = SecondaryViewBottomSheet.topPadding - 8;

              final double topPaddingHeight =
                  ((((oldValue - oldMin) * (maxTopPadding - minTopPadding)) /
                              (oldMax - oldMin)) +
                          minTopPadding)
                      .clamp(0.0, SecondaryViewBottomSheet.topPadding - 8);

              return SizedBox(height: topPaddingHeight);
            },
          ),
        ),
        TabHeader(
          bottomSheetOuterController: widget.bottomSheetOuterController,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: MapConfigurator(
              bottomSheetOuterController: widget.bottomSheetOuterController,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 24)),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        const StoresList(useCompactLayout: true),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
