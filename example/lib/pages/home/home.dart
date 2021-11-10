import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../state/general_provider.dart';
import 'components/app_bar.dart';
import 'components/panel/collapsed_view.dart';
import 'components/map.dart';
import 'components/panel/panel_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PanelController panelController;
  bool loadingVisible = true;

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

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      panelController
          .hide()
          .then((value) => setState(() => loadingVisible = false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, panelController),
      body: Stack(
        children: [
          Consumer<GeneralProvider>(
            builder: (context, provider, _) => SlidingUpPanel(
              body: const MapView(),
              collapsed: const CollapsedView(),
              panel: const PanelView(),
              backdropEnabled: true,
              maxHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              boxShadow: const [],
              isDraggable: provider.cachingEnabled,
              controller: panelController,
            ),
          ),
          Positioned.fill(
            child: Visibility(
              visible: loadingVisible,
              child: Container(
                color: Colors.white,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
