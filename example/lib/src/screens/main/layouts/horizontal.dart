part of '../main.dart';

class _HorizontalLayout extends StatefulWidget {
  const _HorizontalLayout({
    required DraggableScrollableController bottomSheetOuterController,
    required this.mapMode,
    required this.selectedTab,
  }) : _bottomSheetOuterController = bottomSheetOuterController;

  final DraggableScrollableController _bottomSheetOuterController;
  final MapViewMode mapMode;
  final int selectedTab;

  @override
  State<_HorizontalLayout> createState() => _HorizontalLayoutState();
}

class _HorizontalLayoutState extends State<_HorizontalLayout> {
  bool _isSecondaryViewForceExpanded = true;
  bool _isSecondaryViewUserExpanded = false;
  BoxConstraints? _previousConstraints;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 1200 &&
                (_previousConstraints?.maxWidth ?? double.infinity) > 1200) {
              _isSecondaryViewForceExpanded = false;
              _isSecondaryViewUserExpanded = true;
            }
            if (constraints.maxWidth <= 1000 &&
                (_previousConstraints?.maxWidth ?? double.infinity) > 1000) {
              _isSecondaryViewUserExpanded = false;
            }
            if (constraints.maxWidth > 1200 &&
                (_previousConstraints?.maxWidth ?? 0) <= 1200) {
              _isSecondaryViewForceExpanded = true;
            }
            _previousConstraints = constraints;

            final isScrimVisible =
                constraints.maxWidth < 1000 && _isSecondaryViewUserExpanded;

            return Row(
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
                  selectedIndex: widget.selectedTab,
                  labelType: NavigationRailLabelType.all,
                  leading: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Padding(
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
                        if (!_isSecondaryViewForceExpanded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: IconButton(
                              onPressed: () {
                                setState(
                                  () => _isSecondaryViewUserExpanded =
                                      !_isSecondaryViewUserExpanded,
                                );
                              },
                              icon: _isSecondaryViewUserExpanded
                                  ? const Icon(Icons.menu_open)
                                  : const Icon(Icons.menu),
                            ),
                          ),
                      ],
                    ),
                  ),
                  onDestinationSelected: (i) {
                    selectedTabState.value = i;
                    if (!_isSecondaryViewUserExpanded) {
                      setState(() => _isSecondaryViewUserExpanded = true);
                    }
                  },
                ),
                SecondaryViewSide(
                  selectedTab: widget.selectedTab,
                  constraints: constraints,
                  expanded: _isSecondaryViewForceExpanded ||
                      _isSecondaryViewUserExpanded,
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(
                              begin: 0,
                              end: isScrimVisible ? 8 : 0,
                            ),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            builder: (context, sigma, child) => ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: sigma,
                                sigmaY: sigma,
                              ),
                              child: child,
                            ),
                            child: MapView(
                              bottomSheetOuterController:
                                  widget._bottomSheetOuterController,
                              mode: widget.mapMode,
                              layoutDirection: Axis.horizontal,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !isScrimVisible,
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _isSecondaryViewUserExpanded = false,
                              ),
                              child: AnimatedOpacity(
                                opacity: isScrimVisible ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: const DecoratedBox(
                                  decoration:
                                      BoxDecoration(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
