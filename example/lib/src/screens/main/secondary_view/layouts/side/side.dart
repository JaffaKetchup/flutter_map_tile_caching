import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/region_selection_provider.dart';
import '../../contents/download_configuration/download_configuration_view_side.dart';
import '../../contents/home/home_view_side.dart';
import '../../contents/region_selection/region_selection_view_side.dart';

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
            child: switch (selectedTab) {
              0 => HomeViewSide(constraints: constraints),
              1 => context.select<RegionSelectionProvider, bool>(
                  (p) => p.isDownloadSetupPanelVisible,
                )
                    ? const DownloadConfigurationViewSide()
                    : const RegionSelectionViewSide(),
              _ => Placeholder(key: ValueKey(selectedTab)),
            },
          ),
        ),
      );
}
