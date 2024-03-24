import 'package:flutter/material.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:provider/provider.dart';

import 'components/download_progress_indicator.dart';
import 'components/map_view.dart';
import 'components/quit_tiles_preview_indicator.dart';
import 'state/map_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    curve: Curves.linear,
  );

  @override
  void initState() {
    super.initState();

    // Setup animated map controller
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        context.read<MapProvider>()
          ..mapController = _animatedMapController.mapController
          ..animateTo = _animatedMapController.animateTo;
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            const MapView(),
            QuitTilesPreviewIndicator(constraints: constraints),
            DownloadProgressIndicator(constraints: constraints),
          ],
        ),
      );
}
