import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/state/download_provider.dart';
import '../../shared/state/recoverable_regions_provider.dart';
import '../../shared/state/region_selection_provider.dart';
import '../../shared/state/selected_tab_state.dart';
import 'map_view/components/bottom_sheet_wrapper.dart';
import 'map_view/map_view.dart';
import 'secondary_view/contents/region_selection/components/shared/to_config_method.dart';
import 'secondary_view/layouts/bottom_sheet/bottom_sheet.dart';
import 'secondary_view/layouts/bottom_sheet/components/delayed_frame_attached_dependent_builder.dart';
import 'secondary_view/layouts/side/side.dart';

part 'layouts/horizontal.dart';
part 'layouts/vertical.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String route = '/';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _bottomSheetOuterController = DraggableScrollableController();

  StreamSubscription<Iterable<RecoveredRegion<BaseRegion>>>?
      _failedRegionsStreamSub;

  @override
  void initState() {
    super.initState();
    _failedRegionsStreamSub = FMTCRoot.recovery
        .watch(triggerImmediately: true)
        .asyncMap(
          (_) async => (await FMTCRoot.recovery.recoverableRegions).failedOnly,
        )
        .listen(
      (failedRegions) {
        if (!mounted) return;
        context.read<RecoverableRegionsProvider>().failedRegions =
            Map.fromEntries(
          failedRegions.map(
            (r) {
              final region = r.cast<MultiRegion>();
              final existingColor = context
                  .read<RecoverableRegionsProvider>()
                  .failedRegions[region];
              return MapEntry(
                region,
                existingColor ??
                    HSLColor.fromColor(
                      Colors.primaries[
                          Random().nextInt(Colors.primaries.length - 1)],
                    ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _failedRegionsStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: selectedTabState,
        builder: (context, selectedTab, child) {
          final mapMode = switch (selectedTab) {
            0 => MapViewMode.standard,
            1 => MapViewMode.downloadRegion,
            2 => MapViewMode.recovery,
            _ => throw UnimplementedError(),
          };

          return LayoutBuilder(
            builder: (context, constraints) {
              final layoutDirection =
                  constraints.maxWidth < 1200 ? Axis.vertical : Axis.horizontal;

              if (layoutDirection == Axis.vertical) {
                return _VerticalLayout(
                  bottomSheetOuterController: _bottomSheetOuterController,
                  mapMode: mapMode,
                  selectedTab: selectedTab,
                  constrainedHeight: constraints.maxHeight,
                );
              }

              return _HorizontalLayout(
                bottomSheetOuterController: _bottomSheetOuterController,
                mapMode: mapMode,
                selectedTab: selectedTab,
              );
            },
          );
        },
      );
}
