import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/floating_search_bar.dart';
import 'components/home_drawer.dart';
import 'components/map.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: true,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return Scaffold(
      drawer: const HomeDrawer(),
      body: Stack(
        children: [
          const MapView(),
          buildFloatingSearchBar(context),
        ],
      ),
    );
  }
}
