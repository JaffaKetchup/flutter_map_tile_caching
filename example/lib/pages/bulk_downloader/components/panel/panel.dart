/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:stream_transform/stream_transform.dart';

import 'panel_opts.dart';
import 'tile_loaders.dart';

class Panel extends StatefulWidget {
  const Panel({
    Key? key,
    required this.mcm,
    required this.controller,
    required this.mapSource,
  }) : super(key: key);

  final MapCachingManager mcm;
  final MapController controller;
  final String? mapSource;

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              bottom: 68,
              right: 0,
              left: 0,
              child: Column(
                children: [
                  const Expanded(child: PanelOpts()),
                  const SizedBox(height: 10),
                  Text(
                    'You must conform to the ToS of your tile server!',
                    style: TextStyle(
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 58,
              child: StreamBuilder(
                stream: widget.controller.mapEventStream
                    .debounce(const Duration(seconds: 1)),
                builder: (
                  context,
                  evt,
                ) =>
                    TileLoader(
                  key: ValueKey(evt.data.toString()),
                  mcm: widget.mcm,
                  controller: widget.controller,
                  mapSource: widget.mapSource,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/