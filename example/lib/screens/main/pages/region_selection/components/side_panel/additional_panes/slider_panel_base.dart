part of '../parent.dart';

class _SliderPanelBase extends StatelessWidget {
  const _SliderPanelBase({
    required this.constraints,
    required this.layoutDirection,
    required this.isVisible,
    required this.child,
  });

  final BoxConstraints constraints;
  final Axis layoutDirection;
  final bool isVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          opacity: isVisible ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            offset: isVisible
                ? Offset.zero
                : Offset(
                    layoutDirection == Axis.vertical ? -0.5 : 0,
                    layoutDirection == Axis.vertical ? 0 : 0.5,
                  ),
            child: Container(
              width: layoutDirection == Axis.vertical
                  ? null
                  : constraints.maxWidth < 500
                      ? constraints.maxWidth
                      : null,
              height: layoutDirection == Axis.horizontal
                  ? null
                  : constraints.maxHeight < 500
                      ? constraints.maxHeight
                      : null,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(1028),
              ),
              padding: layoutDirection == Axis.vertical
                  ? const EdgeInsets.symmetric(vertical: 22, horizontal: 10)
                  : const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
              child: child,
            ),
          ),
        ),
      );
}
