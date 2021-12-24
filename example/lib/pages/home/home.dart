import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/map.dart';
import 'components/panel/panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MapController mapController;

  @override
  void initState() {
    super.initState();

    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Consumer<GeneralProvider>(
        builder: (context, provider, _) {
          // Layer 1: Get the caching directory
          return FutureBuilder<CacheDirectory>(
            future: MapCachingManager.normalCache,
            builder: (context, cacheDir) {
              if (!cacheDir.hasData) {
                return loadingScreen(
                    context, 'Waiting for the caching directory...');
              }

              // Layer 2: Get the shared preferences instance
              return FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, prefs) {
                  if (!prefs.hasData) {
                    return loadingScreen(
                        context, 'Waiting for persistent storage...');
                  }

                  // Setup provider & default values
                  provider.parentDirectory ??= cacheDir.data!;
                  provider.persistent ??= prefs.data!;

                  provider.storeNameQuiet =
                      provider.persistent!.getString('lastUsedStore') ??
                          'Default Store';

                  // Layer 3: Wait for the map controller to be ready
                  return FutureBuilder<void>(
                    future: mapController.onReady,
                    builder: (context, snapshot) {
                      return Stack(
                        children: [
                          MapView(controller: mapController),
                          AnimatedPositioned(
                            bottom: provider.cachingEnabled ? 0 : -125,
                            width: MediaQuery.of(context).size.width,
                            duration: const Duration(milliseconds: 200),
                            child: const Panel(),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Widget loadingScreen(BuildContext context, String extraInfo) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator.adaptive(),
        const SizedBox(height: 20),
        Text(
          'Loading...\n$extraInfo',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
