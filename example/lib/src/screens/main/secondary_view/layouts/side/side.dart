import 'package:flutter/material.dart';

import '../../contents/home/home_view_side.dart';

class SecondaryViewSide extends StatelessWidget {
  const SecondaryViewSide({
    super.key,
    required this.selectedTab,
    required this.constraints,
  });

  final int selectedTab;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: SizedBox(
          width: (constraints.maxWidth / 3).clamp(440, 560),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.fastOutSlowIn,
                  ),
                ),
                child: child,
              ),
            ),
            child: selectedTab == 0
                ? HomeViewSide(constraints: constraints)
                : const Placeholder(),
          ),
        ),
      );
}
