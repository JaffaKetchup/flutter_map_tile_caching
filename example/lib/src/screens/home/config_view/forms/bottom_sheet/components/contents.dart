part of '../bottom_sheet.dart';

class _ContentPanels extends StatefulWidget {
  const _ContentPanels({required this.bottomSheetOuterController});

  final DraggableScrollableController bottomSheetOuterController;

  @override
  State<_ContentPanels> createState() => _ContentPanelsState();
}

class _ContentPanelsState extends State<_ContentPanels> {
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
              const minTopPadding = ConfigViewBottomSheet.topPadding - 8;

              final double topPaddingHeight =
                  ((((oldValue - oldMin) * (maxTopPadding - minTopPadding)) /
                              (oldMax - oldMin)) +
                          minTopPadding)
                      .clamp(0.0, ConfigViewBottomSheet.topPadding - 8);

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
            child: ConfigPanelMap(
              bottomSheetOuterController: widget.bottomSheetOuterController,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 24)),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        const ConfigPanelStoresSliver(),
      ],
    );
  }
}
