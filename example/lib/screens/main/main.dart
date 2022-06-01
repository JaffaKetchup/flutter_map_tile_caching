import 'package:badges/badges.dart';
import 'package:flutter/material.dart';

import 'pages/map/map.dart';
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
        NavigationDestination(
          icon: Badge(
            position: BadgePosition.topEnd(top: -5, end: -6),
            animationDuration: const Duration(milliseconds: 100),
            showBadge: _currentPageIndex != 2,
            child: const Icon(Icons.download),
          ),
          label: 'Downloader',
        ),
      ];

  static final _pages = <Widget>[
    const MapPage(),
    const StoresPage(),
    Container(
      color: Colors.blue,
      alignment: Alignment.center,
      key: UniqueKey(),
      child: const Text('Page 3'),
    ),
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
  Widget build(BuildContext context) => Scaffold(
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
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
      );
}
