import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/state/region_selection_provider.dart';
import '../../contents/download_configuration/download_configuration_view_side.dart';
import '../../contents/downloading/downloading_view_side.dart';
import '../../contents/home/home_view_side.dart';
import '../../contents/recovery/recovery_view_side.dart';
import '../../contents/region_selection/region_selection_view_side.dart';

class SecondaryViewSide extends StatelessWidget {
  const SecondaryViewSide({
    super.key,
    required this.selectedTab,
    required this.constraints,
    required this.expanded,
  });

  final int selectedTab;
  final BoxConstraints constraints;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: _Contents(
        constraints: constraints,
        selectedTab: selectedTab,
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: Tween<double>(begin: 0, end: 1).animate(animation),
        axis: Axis.horizontal,
        axisAlignment: -1,
        child: child,
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: Offstage(
        key: ValueKey(expanded),
        offstage: !expanded,
        child: child,
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({
    required this.constraints,
    required this.selectedTab,
  });

  final BoxConstraints constraints;
  final int selectedTab;

  @override
  Widget build(BuildContext context) => SizedBox(
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
          child: switch (selectedTab) {
            0 => HomeViewSide(constraints: constraints),
            1 => context.select<DownloadingProvider, bool>((p) => p.isFocused)
                ? const DownloadingViewSide()
                : context.select<RegionSelectionProvider, bool>(
                    (p) => p.isDownloadSetupPanelVisible,
                  )
                    ? const DownloadConfigurationViewSide()
                    : const RegionSelectionViewSide(),
            2 => const RecoveryViewSide(),
            _ => Placeholder(key: ValueKey(selectedTab)),
          },
        ),
      );
}
