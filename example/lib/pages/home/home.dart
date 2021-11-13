import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../misc/components/loading_builder.dart';
import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/map.dart';
import 'components/panel/collapsed_view.dart';
import 'components/panel/panel_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PanelController panelController;
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

    panelController = PanelController();
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Consumer<GeneralProvider>(
        builder: (context, provider, _) {
          return FutureBuilder<CacheDirectory>(
            future: MapCachingManager.normalCache,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return loadingScreen(
                    context, 'Waiting for the caching directory');
              }

              final CacheDirectory parentDirectory = snapshot.data!;

              provider.newMapCachingManager = MapCachingManager(
                parentDirectory,
                provider.storeName,
              );

              return FutureBuilder<void>(
                future: mapController.onReady,
                builder: (context, snapshot) {
                  return SlidingUpPanel(
                    body: MapView(controller: mapController),
                    collapsed: const CollapsedView(),
                    panel: const PanelView(),
                    backdropEnabled: true,
                    maxHeight:
                        MediaQuery.of(context).size.height - kToolbarHeight,
                    boxShadow: const [],
                    isDraggable: provider.cachingEnabled,
                    controller: panelController,
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
