import 'package:flutter/material.dart';

import '../components/delayed_frame_attached_dependent_builder.dart';
import '../components/scrollable_provider.dart';

class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final screenTopPadding =
        MediaQueryData.fromView(View.of(context)).padding.top;
    final outerScrollController =
        BottomSheetScrollableProvider.outerScrollControllerOf(context);
    final innerScrollController =
        BottomSheetScrollableProvider.innerScrollControllerOf(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _PersistentHeader(
        child: DelayedControllerAttachmentBuilder(
          listenable: outerScrollController,
          builder: (context, _) {
            if (!outerScrollController.isAttached ||
                innerScrollController.positions.length != 1) {
              return Column(
                children: [
                  const _Handle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ) +
                        const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              );
            }

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
              child: Column(
                children: [
                  const _Handle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16) +
                        const EdgeInsets.only(bottom: 8),
                    child: AnimatedBuilder(
                      animation: outerScrollController,
                      builder: (context, child) {
                        double calc(double end) {
                          final animationDstPx = outerScrollController
                              .sizeToPixels(1 / 4); // from top
                          final animationTriggerPx =
                              outerScrollController.sizeToPixels(1) -
                                  animationDstPx -
                                  screenTopPadding;

                          return (((outerScrollController.pixels -
                                          animationTriggerPx) *
                                      end) /
                                  animationDstPx)
                              .clamp(0, end);
                        }

                        return Row(
                          children: [
                            SizedBox(width: calc(40), child: child),
                            SizedBox(width: calc(8)),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        );
                      },
                      child: ClipRRect(
                        child: IconButton(
                          onPressed: () {
                            outerScrollController.animateTo(
                              0.3,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            );
                            innerScrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Semantics(
          label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
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
                    .withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );
}

class _PersistentHeader extends SliverPersistentHeaderDelegate {
  const _PersistentHeader({required this.child});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Align(child: child);

  @override
  double get maxExtent => 84;

  @override
  double get minExtent => 84;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
