import 'package:flutter/material.dart';

import '../../../../../shared/components/delayed_frame_attached_dependent_builder.dart';
import '../../contents/home/home_view_bottom_sheet.dart';
import 'components/scrollable_provider.dart';

class SecondaryViewBottomSheet extends StatefulWidget {
  const SecondaryViewBottomSheet({
    super.key,
    required this.selectedTab,
    required this.controller,
  });

  final int selectedTab;
  final DraggableScrollableController controller;

  static const topPadding = kMinInteractiveDimension / 1.5;

  @override
  State<SecondaryViewBottomSheet> createState() =>
      _SecondaryViewBottomSheetState();
}

class _SecondaryViewBottomSheetState extends State<SecondaryViewBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final screenTopPadding =
        MediaQueryData.fromView(View.of(context)).padding.top;

    return LayoutBuilder(
      builder: (context, constraints) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0,
        snap: true,
        expand: false,
        snapSizes: const [0.3],
        controller: widget.controller,
        builder: (context, innerController) =>
            DelayedControllerAttachmentBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            double radius = 18;
            double calcHeight = 0;

            if (widget.controller.isAttached) {
              final maxHeight = widget.controller.sizeToPixels(1);

              final oldValue = widget.controller.pixels;
              final oldMax = maxHeight;
              final oldMin = maxHeight - radius;
              const newMax = 0.0;
              final newMin = radius;

              radius = ((((oldValue - oldMin) * (newMax - newMin)) /
                          (oldMax - oldMin)) +
                      newMin)
                  .clamp(0, radius);

              calcHeight = screenTopPadding -
                  constraints.maxHeight +
                  widget.controller.pixels;
            }

            return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
              child: Column(
                children: [
                  DelayedControllerAttachmentBuilder(
                    listenable: innerController,
                    builder: (context, _) => SizedBox(
                      height: calcHeight.clamp(0, screenTopPadding),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        color: innerController.hasClients &&
                                innerController.offset != 0
                            ? Theme.of(context).colorScheme.surfaceContainer
                            : Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: child,
                    ),
                  ),
                ],
              ),
            );
          },
          child: Stack(
            children: [
              // Future proofing if child is moved out: avoid dependency
              // injection, as that may not be possible in future
              BottomSheetScrollableProvider(
                innerScrollController: innerController,
                child: SizedBox(
                  width: double.infinity,
                  child: widget.selectedTab == 0
                      ? HomeViewBottomSheet(
                          bottomSheetOuterController: widget.controller,
                        )
                      : const Placeholder(),
                ),
              ),
              IgnorePointer(
                child: DelayedControllerAttachmentBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    if (!widget.controller.isAttached) {
                      return const SizedBox.shrink();
                    }

                    final calcHeight = SecondaryViewBottomSheet.topPadding -
                        (screenTopPadding -
                            constraints.maxHeight +
                            widget.controller.pixels);

                    return SizedBox(
                      height: calcHeight.clamp(
                          0, SecondaryViewBottomSheet.topPadding),
                      width: constraints.maxWidth,
                      child: Semantics(
                        label: MaterialLocalizations.of(context)
                            .modalBarrierDismissLabel,
                        container: true,
                        child: Center(
                          child: Container(
                            height: 4,
                            width: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
