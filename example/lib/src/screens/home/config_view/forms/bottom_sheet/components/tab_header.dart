import 'package:flutter/material.dart';

import '../../../../../../shared/components/delayed_frame_attached_dependent_builder.dart';
import 'scrollable_provider.dart';

class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.bottomSheetOuterController,
  });

  final DraggableScrollableController bottomSheetOuterController;

  @override
  Widget build(BuildContext context) {
    final screenTopPadding =
        MediaQueryData.fromView(View.of(context)).padding.top;
    final innerScrollController =
        BottomSheetScrollableProvider.innerScrollControllerOf(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: PersistentHeader(
        child: DelayedControllerAttachmentBuilder(
          listenable: bottomSheetOuterController,
          builder: (context, _) {
            if (!bottomSheetOuterController.isAttached) {
              return const SizedBox.shrink();
            }

            final maxHeight = bottomSheetOuterController.sizeToPixels(1);

            final oldValue = bottomSheetOuterController.pixels;
            final oldMax = maxHeight;
            final oldMin = maxHeight - screenTopPadding;

            const maxMinimizeIndentButtonWidth = 40;
            const maxMinimizeIndentSpacer = 16;
            const minMinimizeIndent = 0;

            final double minimizeIndentButtonWidth = ((((oldValue - oldMin) *
                            (maxMinimizeIndentButtonWidth -
                                minMinimizeIndent)) /
                        (oldMax - oldMin)) +
                    minMinimizeIndent)
                .clamp(0.0, 40);

            final double minimizeIndentSpacer = ((((oldValue - oldMin) *
                            (maxMinimizeIndentSpacer - minMinimizeIndent)) /
                        (oldMax - oldMin)) +
                    minMinimizeIndent)
                .clamp(0.0, 16);

            return AnimatedBuilder(
              animation: innerScrollController,
              builder: (context, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                color: innerScrollController.offset != 0
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : Theme.of(context).colorScheme.surface,
                child: child,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: minimizeIndentButtonWidth,
                      child: ClipRRect(
                        child: IconButton(
                          onPressed: () {
                            bottomSheetOuterController.animateTo(
                              0.3,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            );
                            BottomSheetScrollableProvider
                                    .innerScrollControllerOf(context)
                                .animateTo(
                              0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                    ),
                    SizedBox(width: minimizeIndentSpacer),
                    Text(
                      'Stores & Config',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.help_outline),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PersistentHeader extends SliverPersistentHeaderDelegate {
  const PersistentHeader({required this.child});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Align(child: child);

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
