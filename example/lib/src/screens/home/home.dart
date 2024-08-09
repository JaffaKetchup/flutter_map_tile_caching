import 'package:flutter/material.dart';

import 'config_view/forms/bottom_sheet/bottom_sheet.dart';
import 'config_view/forms/side/side.dart';
import 'map_view/bottom_sheet_wrapper.dart';
import 'map_view/map_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String route = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final bottomSheetOuterController = DraggableScrollableController();

  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final mapMode = switch (selectedTab) {
      0 => MapViewMode.standard,
      1 => MapViewMode.regionSelect,
      _ => throw UnimplementedError(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutDirection =
            constraints.maxWidth < 1200 ? Axis.vertical : Axis.horizontal;

        if (layoutDirection == Axis.vertical) {
          return Scaffold(
            body: BottomSheetMapWrapper(
              bottomSheetOuterController: bottomSheetOuterController,
              mode: mapMode,
              layoutDirection: layoutDirection,
            ),
            bottomSheet:
                ConfigViewBottomSheet(controller: bottomSheetOuterController),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: 'Download',
                ),
                NavigationDestination(
                  icon: Icon(Icons.support_outlined),
                  selectedIcon: Icon(Icons.support),
                  label: 'Recovery',
                ),
              ],
              onDestinationSelected: (i) {
                if (i == 0) {
                  final requiresExpanding =
                      bottomSheetOuterController.size < 0.3;

                  if (selectedTab != 0) {
                    setState(() => selectedTab = 0);
                    if (requiresExpanding) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => bottomSheetOuterController.animateTo(
                          0.3,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                      );
                    }
                  } else {
                    setState(() => selectedTab = i);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => bottomSheetOuterController.animateTo(
                        requiresExpanding ? 0.3 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve:
                            requiresExpanding ? Curves.easeOut : Curves.easeIn,
                      ),
                    );
                  }
                } else {
                  setState(() => selectedTab = i);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => bottomSheetOuterController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeIn,
                    ),
                  );
                }
              },
            ),
          );
        }

        return TweenAnimationBuilder(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          tween: Tween<double>(begin: 0, end: selectedTab == 0 ? 0 : 1),
          builder: (context, colorAnimation, child) => Scaffold(
            backgroundColor: ColorTween(
              begin: Theme.of(context).colorScheme.surfaceContainer,
              end: Theme.of(context).scaffoldBackgroundColor,
            ).lerp(colorAnimation),
            body: child,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.transparent,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: Text('Map'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.download_outlined),
                      selectedIcon: Icon(Icons.download),
                      label: Text('Download'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_outlined),
                      selectedIcon: Icon(Icons.support),
                      label: Text('Recovery'),
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
                  onDestinationSelected: (i) => setState(() => selectedTab = i),
                ),
                ConfigViewSide(
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
  }
}
