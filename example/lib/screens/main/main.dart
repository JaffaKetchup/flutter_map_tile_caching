import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/state/download_provider.dart';
import 'pages/downloader/downloader.dart';
import 'pages/downloading/downloading.dart';
import 'pages/map/map.dart';
import 'pages/recovery/recovery.dart';
import 'pages/settings/settings.dart';
import 'pages/stores/stores.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentPageIndex = 0;
  late final PageController _pageController;

  List<Widget> get _destinations => [
        const NavigationDestination(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
        const NavigationDestination(
          icon: Icon(Icons.folder),
          label: 'Stores',
        ),
        const NavigationDestination(
          icon: Icon(Icons.download),
          label: 'Download',
        ),
        NavigationDestination(
          icon: StreamBuilder(
            stream: FMTC.instance.rootDirectory.stats
                .watchChanges(rootParts: [RootParts.recovery]),
            builder: (context, _) => FutureBuilder<List<RecoveredRegion>>(
              future: FMTC.instance.rootDirectory.recovery.failedRegions,
              builder: (context, snapshot) => Badge(
                position: BadgePosition.topEnd(top: -5, end: -6),
                animationDuration: const Duration(milliseconds: 100),
                showBadge: _currentPageIndex != 3 &&
                    (snapshot.data?.isNotEmpty ?? false),
                child: const Icon(Icons.history),
              ),
            ),
          ),
          label: 'Recover',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];

  static final _pages = <Widget>[
    const MapPage(),
    const StoresPage(),
    Consumer<DownloadProvider>(
      // Use inequality to enter test mode
      builder: (context, provider, _) => provider.downloadProgress == null
          ? const DownloaderPage()
          : const DownloadingPage(),
    ),
    const RecoveryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FMTCBackgroundDownload(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() => _currentPageIndex = index);
              _pageController.animateToPage(
                _currentPageIndex,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            selectedIndex: _currentPageIndex,
            destinations: _destinations,
            labelBehavior: MediaQuery.of(context).size.width > 450
                ? null
                : NavigationDestinationLabelBehavior.onlyShowSelected,
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
        ),
      );
}
