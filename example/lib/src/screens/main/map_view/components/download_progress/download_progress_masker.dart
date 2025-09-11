import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart' hide Path;

part 'components/render_object.dart';

class DownloadProgressMasker extends StatefulWidget {
  const DownloadProgressMasker({
    super.key,
    required this.isVisible,
    required this.tileEvents,
    required this.minZoom,
    required this.maxZoom,
    this.tileSize = 256,
    required this.child,
  });

  final bool isVisible;
  final Stream<TileEvent>? tileEvents;
  final int minZoom;
  final int maxZoom;
  final int tileSize;
  final Widget child;

  // To reset after a download, the `key` must be changed

  @override
  State<DownloadProgressMasker> createState() => _DownloadProgressMaskerState();
}

class _DownloadProgressMaskerState extends State<DownloadProgressMasker> {
  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: StreamBuilder(
          stream: widget.tileEvents
              ?.where(
                (evt) => evt is SuccessfulTileEvent || evt is SkippedTileEvent,
              )
              .map((evt) => evt.coordinates),
          builder: (context, coords) => DownloadProgressMaskerRenderObject(
            isVisible: widget.isVisible,
            mapCamera: MapCamera.of(context),
            latestTileCoordinates: coords.data == null
                ? null
                : TileCoordinates(
                    coords.requireData.$1,
                    coords.requireData.$2,
                    coords.requireData.$3,
                  ),
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            tileSize: widget.tileSize,
            child: widget.child,
          ),
        ),
      );
}
