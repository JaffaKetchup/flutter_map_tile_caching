import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DownloadProgressCover extends SingleChildRenderObjectWidget {
  const DownloadProgressCover({
    super.key,
    super.child,
    required this.mapCamera,
  });

  final MapCamera mapCamera;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _DownloadProgressCoverMask(mapCamera: mapCamera);

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    _DownloadProgressCoverMask renderObject,
  ) {
    renderObject.mapCamera = mapCamera;
  }
}

class _DownloadProgressCoverMask extends RenderProxyBox {
  _DownloadProgressCoverMask({
    required MapCamera mapCamera,
  }) : _mapCamera = mapCamera;

  MapCamera _mapCamera;
  MapCamera get mapCamera => _mapCamera;
  set mapCamera(MapCamera value) {
    if (value == mapCamera) return;
    _mapCamera = value;
    markNeedsPaint();
  }

  static ColorFilter _grayscale(double percentage) {
    final amount = 1 - percentage;
    return ColorFilter.matrix([
      (0.2126 + 0.7874 * amount),
      (0.7152 - 0.7152 * amount),
      (0.0722 - 0.0722 * amount),
      0,
      0,
      (0.2126 - 0.2126 * amount),
      (0.7152 + 0.2848 * amount),
      (0.0722 - 0.0722 * amount),
      0,
      0,
      (0.2126 - 0.2126 * amount),
      (0.7152 - 0.7152 * amount),
      (0.0722 + 0.9278 * amount),
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  final targetCoord = const LatLng(45.3271, 14.4422);
  final tileSize = 256;
  late final targetTiles = List.generate(
    7,
    (z) {
      final zoom = z + 12;
      final (x, y) = mapCamera.crs
          .latLngToXY(targetCoord, mapCamera.crs.scale(zoom.toDouble()));
      return TileCoordinates(
        (x / tileSize).floor(),
        (y / tileSize).floor(),
        zoom,
      );
    },
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    final layerHandles = Iterable.generate(
      double.maxFinite.toInt(),
      (_) => LayerHandle<ColorFilterLayer>(),
    );

    final rects = targetTiles.map((tile) {
      final nw = mapCamera.latLngToScreenPoint(
        mapCamera.crs.pointToLatLng(tile * tileSize, tile.z.toDouble()),
      );
      final se = mapCamera.latLngToScreenPoint(
        mapCamera.crs.pointToLatLng(
          (tile + const Point(1, 1)) * tileSize,
          tile.z.toDouble(),
        ),
      );
      return Rect.fromPoints(nw.toOffset(), se.toOffset());
    });

    context.pushColorFilter(
      offset,
      _grayscale(1),
      (context, offset) => context.paintChild(child!, offset),

      //oldLayer: layerHandles.elementAt(layerHandleIndex).layer,
    );

    // context.paintChild(child!, offset);

    int layerHandleIndex = 0;
    for (int i = 0; i < rects.length; i++) {
      final rect = rects.elementAt(i);

      /*final oldMin = 0;
      final oldMax = rects.length - 1;
      final newMin = 0;
      final newMax = 1;
      final oldRange = (oldMax - oldMin);
      final newRange = (newMax - newMin);
      final amount = (((i - oldMin) * newRange) / oldRange) + newMin;
      print('$i: $amount');*/

      layerHandles.elementAt(layerHandleIndex).layer = context.pushColorFilter(
        offset,
        _grayscale(((rects.length - 1) - i) / 7),
        (context, offset) => context.pushClipRect(
          true,
          offset,
          rect,
          (context, offset) => context.paintChild(child!, offset),
        ),
        oldLayer: layerHandles.elementAt(layerHandleIndex).layer,
      );

      layerHandleIndex++;
    }

    /*const double chessSize = 100;
    final rows = size.height ~/ chessSize;
    final cols = size.width ~/ chessSize;

    int i = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        /*_clipLayerHandles[childIndex].layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) =>
            context.paintChild(child!, offset + Offset(childIndex * 50, 0)),
        oldLayer: _clipLayerHandles[childIndex].layer,
      );*/
        layerHandles.elementAt(i).layer = context.pushColorFilter(
          offset,
          _grayscale(i % 2),
          (context, offset) => context.pushClipRect(
            true,
            offset,
            Rect.fromLTWH(
              c * chessSize,
              r * chessSize,
              chessSize,
              chessSize,
            ),
            (context, offset) => context.paintChild(child!, offset),
          ),
          oldLayer: layerHandles.elementAt(i).layer,
        );
        i++;
      }
    }*/

    context.canvas.drawCircle(offset, 100, Paint()..color = Colors.blue);

    int rectI = 0;
    for (final rect in rects) {
      context.canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 3,
      );
      rectI++;
    }
  }
}
