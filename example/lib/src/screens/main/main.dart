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
                return Scaffold(
                  body: BottomSheetMapWrapper(
                    bottomSheetOuterController: _bottomSheetOuterController,
                    mode: mapMode,
                    layoutDirection: layoutDirection,
                  ),
                  bottomSheet: SecondaryViewBottomSheet(
                    selectedTab: selectedTab,
                    controller: _bottomSheetOuterController,
                  ),
                  floatingActionButton: selectedTab == 1 &&
                          context
                              .watch<RegionSelectionProvider>()
                              .constructedRegions
                              .isNotEmpty
                      ? DelayedControllerAttachmentBuilder(
                          listenable: _bottomSheetOuterController,
                          builder: (context, _) => AnimatedBuilder(
                            animation: _bottomSheetOuterController,
                            builder: (context, _) => FloatingActionButton(
                              onPressed: () async {
                                final currentPx =
                                    _bottomSheetOuterController.pixels;
                                await _bottomSheetOuterController.animateTo(
                                  2 / 3,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                                if (!context.mounted) return;
                                prepareDownloadConfigView(
                                  context,
                                  shouldShowConfig: currentPx > 33,
                                );
                              },
                              tooltip: _bottomSheetOuterController.pixels <= 33
                                  ? 'Show regions'
                                  : 'Configure download',
                              child: _bottomSheetOuterController.pixels <= 33
                                  ? const Icon(Icons.library_add_check)
                                  : const Icon(Icons.tune),
                            ),
                          ),
                        )
                      : null,
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: selectedTab,
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map),
                        label: 'Map',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.download_outlined),
                        selectedIcon: Icon(Icons.download),
                        label: 'Download',
                      ),
                      NavigationDestination(
                        icon: Selector<RecoverableRegionsProvider, int>(
                          selector: (context, provider) =>
                              provider.failedRegions.length,
                          builder: (context, count, child) => count == 0
                              ? child!
                              : Badge.count(count: count, child: child),
                          child: const Icon(Icons.support_outlined),
                        ),
                        selectedIcon: const Icon(Icons.support),
                        label: 'Recovery',
                      ),
                    ],
                    onDestinationSelected: (i) {
                      selectedTabState.value = i;
                      if (i == 1) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _bottomSheetOuterController.animateTo(
                            32 / constraints.maxHeight,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        );
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _bottomSheetOuterController.animateTo(
                            0.3,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        );
                      }
                    },
                  ),
                );
              }

              return Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                body: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      NavigationRail(
                        backgroundColor: Colors.transparent,
                        destinations: [
                          const NavigationRailDestination(
                            icon: Icon(Icons.map_outlined),
                            selectedIcon: Icon(Icons.map),
                            label: Text('Map'),
                          ),
                          NavigationRailDestination(
                            icon: Selector<DownloadingProvider, bool>(
                              selector: (context, provider) =>
                                  provider.isDownloading,
                              builder: (context, isDownloading, child) =>
                                  !isDownloading ? child! : Badge(child: child),
                              child: const Icon(Icons.download_outlined),
                            ),
                            selectedIcon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                          NavigationRailDestination(
                            icon: Selector<RecoverableRegionsProvider, int>(
                              selector: (context, provider) =>
                                  provider.failedRegions.length,
                              builder: (context, count, child) => count == 0
                                  ? child!
                                  : Badge.count(count: count, child: child),
                              child: const Icon(Icons.support_outlined),
                            ),
                            selectedIcon: const Icon(Icons.support),
                            label: const Text('Recovery'),
                          ),
                        ],
                        selectedIndex: selectedTab,
                        labelType: NavigationRailLabelType.all,
                        leading: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/icons/ProjectIcon.png',
                              width: 54,
                              height: 54,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        onDestinationSelected: (i) =>
                            selectedTabState.value = i,
                      ),
                      SecondaryViewSide(
                        selectedTab: selectedTab,
                        constraints: constraints,
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: MapView(
                            bottomSheetOuterController:
                                _bottomSheetOuterController,
                            mode: mapMode,
                            layoutDirection: layoutDirection,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
}
