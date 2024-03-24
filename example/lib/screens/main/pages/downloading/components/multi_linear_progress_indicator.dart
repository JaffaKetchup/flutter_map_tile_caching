import 'package:flutter/material.dart';

typedef IndividualProgress = ({num value, Color color, Widget? child});

class MulitLinearProgressIndicator extends StatefulWidget {
  const MulitLinearProgressIndicator({
    super.key,
    required this.progresses,
    this.maxValue = 1,
    this.backgroundChild,
    this.height = 24,
    this.radius,
    this.childAlignment = Alignment.centerRight,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  final List<IndividualProgress> progresses;
  final num maxValue;
  final Widget? backgroundChild;
  final double height;
  final BorderRadiusGeometry? radius;
  final AlignmentGeometry childAlignment;
  final Duration animationDuration;

  @override
  State<MulitLinearProgressIndicator> createState() =>
      _MulitLinearProgressIndicatorState();
}

class _MulitLinearProgressIndicatorState
    extends State<MulitLinearProgressIndicator> {
  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) => ClipRRect(
            borderRadius:
                widget.radius ?? BorderRadius.circular(widget.height / 2),
            child: SizedBox(
              height: widget.height,
              width: constraints.maxWidth,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: widget.radius ??
                            BorderRadius.circular(widget.height / 2),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: widget.height / 2,
                      ),
                      alignment: widget.childAlignment,
                      child: widget.backgroundChild,
                    ),
                  ),
                  ...widget.progresses.map(
                    (e) => AnimatedPositioned(
                      height: widget.height,
                      left: 0,
                      width: (constraints.maxWidth / widget.maxValue) * e.value,
                      duration: widget.animationDuration,
                      child: Container(
                        decoration: BoxDecoration(
                          color: e.color,
                          borderRadius: widget.radius ??
                              BorderRadius.circular(widget.height / 2),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: widget.height / 2,
                        ),
                        alignment: widget.childAlignment,
                        child: e.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
