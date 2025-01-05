import 'dart:ui';
import 'package:flutter/material.dart';

class CustomSingleSlidableAction extends StatefulWidget {
  const CustomSingleSlidableAction({
    required super.key,
    required this.unconfirmedIcon,
    required this.confirmedIcon,
    required this.color,
    required this.alignment,
    required this.dismissThreshold,
    this.showLoader = false,
  });

  final IconData unconfirmedIcon;
  final IconData confirmedIcon;
  final Color color;
  final Alignment alignment;
  final double dismissThreshold;
  final bool showLoader;

  @override
  State<CustomSingleSlidableAction> createState() =>
      _CustomSingleSlidableActionState();
}

class _CustomSingleSlidableActionState extends State<CustomSingleSlidableAction>
    with SingleTickerProviderStateMixin {
  late final _inkWellKey = GlobalKey();

  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 120),
    vsync: this,
  );
  late final _sizeAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInQuart,
    reverseCurve: Curves.easeIn,
  )..addStatusListener(_autoReverser);
  late final _rotationAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.elasticIn,
  )..addStatusListener(_autoReverser);
  void _autoReverser(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animationController.reverse();
    }
  }

  final _scaleTween = Tween<double>(begin: 1, end: 1.15);
  final _rotationTween = Tween<double>(begin: 0, end: 0.06);

  double _prevMaxWidth = 0;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Expanded(
        child: LayoutBuilder(
          builder: (context, innerConstraints) {
            final willAct =
                innerConstraints.maxWidth >= widget.dismissThreshold;

            if (innerConstraints.maxWidth > _prevMaxWidth &&
                _prevMaxWidth < widget.dismissThreshold &&
                willAct) {
              _animationController.forward();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final box = _inkWellKey.currentContext!.findRenderObject()!
                    as RenderBox;
                final position = box.localToGlobal(
                  Offset(
                    lerpDouble(
                      0,
                      box.size.width,
                      (widget.alignment.x.clamp(-1, 1) + 1) / 2,
                    )!,
                    box.size.height / 2,
                  ),
                );

                _inkWellKey.currentContext!.visitChildElements((element) {
                  assert(
                    element.widget.runtimeType.toString() ==
                            '_InkResponseStateWidget' &&
                        element is StatefulElement,
                    'Child elements traversal failed',
                  );

                  final inkResponseState =
                      (element as StatefulElement).state as dynamic;

                  // Shenanigans
                  // ignore: avoid_dynamic_calls
                  inkResponseState.handleTapDown(
                    TapDownDetails(globalPosition: position),
                  );
                  // Shenanigans
                  // ignore: avoid_dynamic_calls
                  inkResponseState.handleLongPress();
                });
              });
            }

            _prevMaxWidth = innerConstraints.maxWidth;

            final icon = Flexible(
              child: RotationTransition(
                turns: _rotationTween.animate(_rotationAnimation),
                child: ScaleTransition(
                  scale: _scaleTween.animate(_sizeAnimation),
                  child: SizedBox.square(
                    dimension: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: willAct
                          ? Icon(
                              key: const ValueKey(1),
                              widget.confirmedIcon,
                              color: Theme.of(context).colorScheme.surface,
                            )
                          : Icon(
                              key: const ValueKey(0),
                              widget.unconfirmedIcon,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                    ),
                  ),
                ),
              ),
            );

            final loader = Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor:
                      Tween<double>(begin: 0, end: 1).animate(animation),
                  axis: Axis.horizontal,
                  fixedCrossAxisSizeFactor: 1,
                  child: child,
                ),
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                child: widget.showLoader
                    ? UnconstrainedBox(
                        constrainedAxis: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: widget.alignment.x >= 0 ? 12 : 0,
                            right: widget.alignment.x <= 0 ? 12 : 0,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 24,
                              maxWidth: 24,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.surface,
                                ),
                                strokeAlign:
                                    CircularProgressIndicator.strokeAlignInside,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );

            return Material(
              color: Colors.transparent,
              child: InkWell(
                key: _inkWellKey,
                radius: innerConstraints.maxWidth,
                splashFactory: InkSparkle.splashFactory,
                canRequestFocus: false,
                child: TweenAnimationBuilder(
                  tween: ColorTween(
                    begin: widget.color.withAlpha(204),
                    end: willAct ? widget.color : widget.color.withAlpha(204),
                  ),
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeIn,
                  builder: (context, color, child) => Ink(
                    color: color,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: double.infinity,
                    child: child,
                  ),
                  child: Opacity(
                    opacity: innerConstraints.maxWidth.clamp(0, 56) / 56,
                    child: Row(
                      mainAxisAlignment: widget.alignment.x > 0
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: widget.alignment.x > 0
                          ? [icon, loader]
                          : [loader, icon],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}
