import 'dart:io';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:provider/provider.dart';

import '../../shared/state/download_provider.dart';
import 'pages/downloader/downloader.dart';
import 'pages/downloading/downloading.dart';
import 'pages/map/map_view.dart';
import 'pages/recovery/recovery.dart';
import 'pages/settingsAndAbout/settings_and_about.dart';
import 'pages/stores/stores.dart';
import 'pages/update/update.dart';

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
  //static const Color backgroundColor = Color(0xFFeaf6f5);
  late final PageController _pageController;
  int _currentPageIndex = 0;
  bool extended = false;

  List<NavigationDestination> get _destinations => [
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
                child: const Icon(Icons.running_with_errors),
              ),
            ),
          ),
          label: 'Recover',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        if (Platform.isWindows || Platform.isAndroid)
          const NavigationDestination(
            icon: Icon(Icons.update),
            label: 'Update',
          ),
      ];

  List<Widget> get _pages => [
        const MapPage(),
        const StoresPage(),
        Consumer<DownloadProvider>(
          builder: (context, provider, _) => provider.downloadProgress == null
              ? const DownloaderPage()
              : const DownloadingPage(),
        ),
        RecoveryPage(moveToDownloadPage: () => _onDestinationSelected(2)),
        const SettingsAndAboutPage(),
        if (Platform.isWindows || Platform.isAndroid) const UpdatePage(),
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
  Widget build(BuildContext context) => FMTCBackgroundDownload(
        child: Scaffold(
          bottomNavigationBar: MediaQuery.of(context).size.width > 950
              ? null
              : NavigationBar(
                  backgroundColor:
                      Theme.of(context).navigationBarTheme.backgroundColor,
                  onDestinationSelected: _onDestinationSelected,
                  selectedIndex: _currentPageIndex,
                  destinations: _destinations,
                  labelBehavior: MediaQuery.of(context).size.width > 450
                      ? null
                      : NavigationDestinationLabelBehavior.alwaysHide,
                  height: 70,
                ),
          body: Row(
            children: [
              if (MediaQuery.of(context).size.width > 950)
                NavigationRail(
                  onDestinationSelected: _onDestinationSelected,
                  selectedIndex: _currentPageIndex,
                  groupAlignment: 0,
                  extended: extended,
                  destinations: _destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          label: Text(d.label),
                          padding: const EdgeInsets.all(10),
                        ),
                      )
                      .toList(),
                  leading: Row(
                    children: [
                      AnimatedContainer(
                        width: extended ? 205 : 0,
                        duration: kThemeAnimationDuration,
                        curve: Curves.easeInOut,
                      ),
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: kThemeAnimationDuration,
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: Icon(
                            extended ? Icons.menu_open : Icons.menu,
                            key: UniqueKey(),
                          ),
                        ),
                        onPressed: () => setState(() => extended = !extended),
                        tooltip: !extended ? 'Extend Menu' : 'Collapse Menu',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: MediaQuery.of(context).size.width > 950
                        ? const Radius.circular(16)
                        : Radius.zero,
                    bottomLeft: MediaQuery.of(context).size.width > 950
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
