part of '../main.dart';

class _HorizontalLayout extends StatelessWidget {
  const _HorizontalLayout({
    required DraggableScrollableController bottomSheetOuterController,
    required this.mapMode,
    required this.selectedTab,
  }) : _bottomSheetOuterController = bottomSheetOuterController;

  final DraggableScrollableController _bottomSheetOuterController;
  final MapViewMode mapMode;
  final int selectedTab;

  @override
  Widget build(BuildContext context) => Scaffold(
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
                          provider.storeName != null,
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
                onDestinationSelected: (i) => selectedTabState.value = i,
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
                    bottomSheetOuterController: _bottomSheetOuterController,
                    mode: mapMode,
                    layoutDirection: Axis.horizontal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
