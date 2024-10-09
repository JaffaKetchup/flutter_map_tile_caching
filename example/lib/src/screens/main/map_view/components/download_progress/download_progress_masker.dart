import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

part 'components/greyscale_masker.dart';

class DownloadProgressMasker extends StatefulWidget {
  const DownloadProgressMasker({
    super.key,
    required this.tileCoordinatesStream,
    required this.minZoom,
    required this.maxZoom,
    this.tileSize = 256,
    required this.child,
  });

  final Stream<TileCoordinates>? tileCoordinatesStream;
  final int minZoom;
  final int maxZoom;
  final int tileSize;
  final TileLayer child;

  @override
  State<DownloadProgressMasker> createState() => _DownloadProgressMaskerState();
}

class _DownloadProgressMaskerState extends State<DownloadProgressMasker> {
  @override
  Widget build(BuildContext context) {
    if (widget.tileCoordinatesStream case final tcs?) {
      return RepaintBoundary(
        child: GreyscaleMasker(
          /*key: ObjectKey(
            (
              widget.minZoom,
              widget.maxZoom,
              widget.tileCoordinatesStream,
              widget.tileSize,
            ),
          ),*/
          mapCamera: MapCamera.of(context),
          tileCoordinatesStream: tcs,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
          tileSize: widget.tileSize,
          child: widget.child,
        ),
      );
    }
    return widget.child;
  }
}
