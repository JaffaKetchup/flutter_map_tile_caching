import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import 'pages/downloading/downloading.dart';
import 'pages/downloading/state/downloading_provider.dart';
import 'pages/map/map_view.dart';
import 'pages/map/state/map_provider.dart';
import 'pages/recovery/recovery.dart';
import 'pages/region_selection/region_selection.dart';
import 'pages/stores/stores.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.damagedDatabaseDeleted,
  });

  final String? damagedDatabaseDeleted;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  bool extended = false;

  List<NavigationDestination> get _destinations => [
        const NavigationDestination(
          label: 'Map',
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
        ),
        const NavigationDestination(
          label: 'Stores',
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
        ),
        const NavigationDestination(
          label: 'Download',
          icon: Icon(Icons.download_outlined),
          selectedIcon: Icon(Icons.download),
        ),
        NavigationDestination(
          label: 'Recover',
          icon: StreamBuilder(
            stream: FMTC.instance.rootDirectory.stats
                .watchChanges()
                .asBroadcastStream(),
            builder: (context, _) => FutureBuilder<List<RecoveredRegion>>(
              future: FMTC.instance.rootDirectory.recovery.failedRegions,
              builder: (context, snapshot) => Badge(
                position: BadgePosition.topEnd(top: -5, end: -6),
                badgeAnimation: const BadgeAnimation.size(
                  animationDuration: Duration(milliseconds: 100),
                ),
                showBadge: _currentPageIndex != 3 &&
                    (snapshot.data?.isNotEmpty ?? false),
                child: const Icon(Icons.support),
              ),
            ),
          ),
        ),
      ];

  List<Widget> get _pages => [
        const MapPage(),
        const StoresPage(),
        Selector<DownloadingProvider, Stream<DownloadProgress>?>(
          selector: (context, provider) => provider.downloadProgress,
          builder: (context, downloadProgress, _) => downloadProgress == null
              ? const RegionSelectionPage()
              : const DownloadingPage(),
        ),
        RecoveryPage(moveToDownloadPage: () => _onDestinationSelected(2)),
      ];

  void _onDestinationSelected(int index) {
    setState(() => _currentPageIndex = index);
    _pageController.animateToPage(
      _currentPageIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: _currentPageIndex);
    if (widget.damagedDatabaseDeleted != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'At least one corrupted database has been deleted.\n${widget.damagedDatabaseDeleted}',
            ),
          ),
        ),
      );
    }
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: MediaQuery.sizeOf(context).width > 950
            ? null
            : NavigationBar(
                backgroundColor:
                    Theme.of(context).navigationBarTheme.backgroundColor,
                onDestinationSelected: _onDestinationSelected,
                selectedIndex: _currentPageIndex,
                destinations: _destinations,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                height: 70,
              ),
        floatingActionButton: _currentPageIndex != 0
            ? null
            : Consumer<MapProvider>(
                builder: (context, mapProvider, _) => FloatingActionButton(
                  onPressed: () {
                    switch (mapProvider.followState) {
                      case UserLocationFollowState.off:
                        mapProvider.followState =
                            UserLocationFollowState.standard;
                        mapProvider.trackLocation(navigation: false);
                        mapProvider.mapController.rotate(0);
                        break;
                      case UserLocationFollowState.standard:
                        mapProvider.followState =
                            UserLocationFollowState.navigation;
                        mapProvider.trackLocation(navigation: true);
                        mapProvider.trackHeading();
                        break;
                      case UserLocationFollowState.navigation:
                        mapProvider.followState = UserLocationFollowState.off;
                        mapProvider.mapController.rotate(0);
                        break;
                    }
                    setState(() {});
                  },
                  child: Icon(
                    switch (mapProvider.followState) {
                      UserLocationFollowState.off => Icons.gps_off,
                      UserLocationFollowState.standard => Icons.gps_fixed,
                      UserLocationFollowState.navigation => Icons.navigation,
                    },
                  ),
                ),
              ),
        body: Row(
          children: [
            if (MediaQuery.sizeOf(context).width > 950)
              NavigationRail(
                onDestinationSelected: _onDestinationSelected,
                selectedIndex: _currentPageIndex,
                labelType: NavigationRailLabelType.all,
                groupAlignment: 0,
                destinations: _destinations
                    .map(
                      (d) => NavigationRailDestination(
                        label: Text(d.label),
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    )
                    .toList(),
              ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: MediaQuery.sizeOf(context).width > 950
                        ? BorderSide(color: Theme.of(context).dividerColor)
                        : BorderSide.none,
                    bottom: MediaQuery.sizeOf(context).width <= 950
                        ? BorderSide(color: Theme.of(context).dividerColor)
                        : BorderSide.none,
                  ),
                ),
                position: DecorationPosition.foreground,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _pages,
                ),
              ),
            ),
          ],
        ),
      );
}
