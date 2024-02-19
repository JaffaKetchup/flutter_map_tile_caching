import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import 'pages/downloading/downloading.dart';
import 'pages/downloading/state/downloading_provider.dart';
import 'pages/map/map_page.dart';
import 'pages/recovery/recovery.dart';
import 'pages/region_selection/region_selection.dart';
import 'pages/stores/stores.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final _pageController = PageController(initialPage: _currentPageIndex);
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
            stream: FMTCRoot.stats.watchChanges().asBroadcastStream(),
            builder: (context, _) => FutureBuilder<List<RecoveredRegion>>(
              future: FMTCRoot.recovery.failedRegions,
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
              : DownloadingPage(
                  moveToMapPage: () =>
                      _onDestinationSelected(0, cancelTilesPreview: false),
                ),
        ),
        RecoveryPage(moveToDownloadPage: () => _onDestinationSelected(2)),
      ];

  void _onDestinationSelected(int index, {bool cancelTilesPreview = true}) {
    setState(() => _currentPageIndex = index);
    _pageController
        .animateToPage(
      _currentPageIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    )
        .then(
      (_) {
        if (cancelTilesPreview) {
          final dp = context.read<DownloadingProvider>();
          dp.tilesPreviewStreamSub
              ?.cancel()
              .then((_) => dp.tilesPreviewStreamSub = null);
        }
      },
    );
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
                onDestinationSelected: _onDestinationSelected,
                selectedIndex: _currentPageIndex,
                destinations: _destinations,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                height: 70,
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 3,
                        ),
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
