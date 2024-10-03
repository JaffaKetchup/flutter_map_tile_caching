import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GreyscaleMasker extends SingleChildRenderObjectWidget {
  const GreyscaleMasker({
    super.key,
    super.child,
    required this.mapCamera,
    required this.tileCoordinates,
    required this.minZoom,
    required this.maxZoom,
    required this.tileSize,
  });

  final MapCamera mapCamera;
  final Stream<TileCoordinates> tileCoordinates;
  final int minZoom;
  final int maxZoom;
  final int tileSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _GreyscaleMaskerRenderer(
        mapCamera: mapCamera,
        tileCoordinates: tileCoordinates,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileSize: tileSize,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    _GreyscaleMaskerRenderer renderObject,
  ) {
    renderObject.mapCamera = mapCamera;
  }
}

class _GreyscaleMaskerRenderer extends RenderProxyBox {
  _GreyscaleMaskerRenderer({
    required MapCamera mapCamera,
    required Stream<TileCoordinates> tileCoordinates,
    required this.minZoom,
    required this.maxZoom,
    required this.tileSize,
  })  : assert(
          maxZoom - minZoom < 32,
          'Unable to store large numbers that result from handling `maxZoom` '
          '- `minZoom`',
        ),
        _mapCamera = mapCamera {
    // Precalculate for more efficient percentage calculations later
    _possibleSubtilesCountPerZoomLevel = Uint64List((maxZoom - minZoom) + 1);
    int p = 0;
    for (int i = minZoom; i < maxZoom; i++) {
      _possibleSubtilesCountPerZoomLevel[p] = pow(4, maxZoom - i).toInt();
      p++;
    }
    _possibleSubtilesCountPerZoomLevel[p] = 0;

    // Handle incoming tile coordinates
    tileCoordinates.listen(_incomingTileHandler);
  }

  MapCamera _mapCamera;
  MapCamera get mapCamera => _mapCamera;
  set mapCamera(MapCamera value) {
    if (value == mapCamera) return;
    _mapCamera = value;
    markNeedsPaint();
  }

  final int minZoom;
  final int maxZoom;
  final int tileSize;

  late final StreamSubscription<TileCoordinates> _tileCoordinatesSub;

  /// Maps tiles of a download to the number of subtiles downloaded
  ///
  /// Due to the multi-threaded nature of downloading, it is important to note
  /// when modifying this map that the parentist tile may not yet be
  /// registered in the map if it has been queued for another thread. In this
  /// case, the value should be initialised to 0, then the thread which
  /// eventually downloads the parentist tile should increment the value. With
  /// the exception of this case, the existence of a tile key is an indication
  /// that that parent tile has been downloaded.
  ///
  /// TODO: Use minZoom system and another 'temp' mapping to prevent the issue
  /// above by treating as minZoom until minnerZoom.
  ///
  /// The map assigned must be immutable: it must be reconstructed for every
  /// update.
  final Map<TileCoordinates, int> _tileMapping = SplayTreeMap(
    (a, b) => a.z.compareTo(b.z) | a.x.compareTo(b.x) | a.y.compareTo(b.y),
  );

  //final Set<TileCoordinates> _tempTileStorage = {};

  /// The number of subtiles a tile at the zoom level (index) may have
  late final Uint64List _possibleSubtilesCountPerZoomLevel;

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

  /*final targetCoord = const LatLng(45.3271, 14.4422);
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
  );*/

  // Generate fresh layer handles lazily, as many as is needed
  //
  // Required to allow the child to be painted multiple times.
  final _layerHandles = Iterable.generate(
    double.maxFinite.toInt(),
    (_) => LayerHandle<ColorFilterLayer>(),
  );

  static TileCoordinates _recurseTileToMinZoomLevelParentWithCallback(
    TileCoordinates tile,
    int absMinZoom,
    void Function(TileCoordinates tile) zoomLevelCallback,
  ) {
    assert(
      tile.z >= absMinZoom,
      '`tile.z` must be greater than or equal to `minZoom`',
    );

    zoomLevelCallback(tile);

    if (tile.z == absMinZoom) return tile;

    return _recurseTileToMinZoomLevelParentWithCallback(
      TileCoordinates(tile.x ~/ 2, tile.y ~/ 2, tile.z - 1),
      absMinZoom,
      zoomLevelCallback,
    );
  }

  void _incomingTileHandler(TileCoordinates tile) {
    assert(tile.z >= minZoom, 'Incoming `tile` has zoom level below minimum');
    assert(tile.z <= maxZoom, 'Incoming `tile` has zoom level above maximum');

    //print(tile);

    _recurseTileToMinZoomLevelParentWithCallback(
      tile,
      minZoom,
      (intermediateZoomTile) {
        final maxSubtilesCount = _possibleSubtilesCountPerZoomLevel[
            intermediateZoomTile.z - minZoom];
        //print('${intermediateZoomTile.z}: $maxSubtilesCount');

        if (_tileMapping[intermediateZoomTile] case final existingValue?) {
          /*assert(
            existingValue < maxSubtilesCount,
            'Existing subtiles count cannot be larger than theoretical max '
            'subtiles count ($intermediateZoomTile: $existingValue >= '
            '$maxSubtilesCount)',
          );*/

          /*if (existingValue + 1 == maxSubtilesCount &&
              _tileMapping[TileCoordinates(
                    tile.x ~/ 2,
                    tile.y ~/ 2,
                    tile.z - 1,
                  )] ==
                  _possibleSubtilesCountPerZoomLevel[tile.z - 1 - minZoom] -
                      1) {
            _tileMapping.remove(intermediateZoomTile);
            debugPrint(
              'Removing $intermediateZoomTile, reached max subtiles count of '
              '$maxSubtilesCount & parent contains max tiles',
            );
          } else {*/
          _tileMapping[intermediateZoomTile] = existingValue + 1;
          //}
        } else {
          /*if (maxSubtilesCount == 0 &&
              _tileMapping[TileCoordinates(
                    tile.x ~/ 2,
                    tile.y ~/ 2,
                    tile.z - 1,
                  )] ==
                  _possibleSubtilesCountPerZoomLevel[tile.z - 1 - minZoom] -
                      1) {
            debugPrint('Not making new key $intermediateZoomTile');
          } else {*/
          _tileMapping[intermediateZoomTile] = 0;
          //debugPrint('Making new key $intermediateZoomTile');
          //}
        }

        /*if (_tileMapping[intermediateZoomTile] case final existingValue?) {
          _tileMapping[intermediateZoomTile] = existingValue + 1;
        } else {
          _tempTileStorage.add(intermediateZoomTile);
          assert(
            _tempTileStorage.length < 50,
            'CAUTION! Temp buffer too full. Likely a bug, or too many threads & small region.',
          );
        }*/
      },
    );

    /*final (int, int) parentistTile;

    if (tile.z == minZoom) {
      parentistTile = (tile.x, tile.y);
    } else {
      final parentistTileWithZoom =
          _recurseTileToMinZoomLevelParent(tile, minZoom);
      parentistTile = (parentistTileWithZoom.x, parentistTileWithZoom.y);
    }


    _tileMapping[parentistTile] = (_tileMapping[parentistTile] ?? -1) + 1;*/

    //print(_tileMapping);

    markNeedsPaint();
  }

  @override
  void dispose() {
    _tileCoordinatesSub.cancel();
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    /*final rects = targetTiles.map((tile) {
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
    });*/

    context.pushColorFilter(
      offset,
      _grayscale(1),
      (context, offset) => context.paintChild(child!, offset),
    );

    int layerHandleIndex = 0;
    for (int i = 0; i < _tileMapping.length; i++) {
      final MapEntry(key: tile, value: subtilesCount) =
          _tileMapping.entries.elementAt(i);

      final nw = mapCamera.latLngToScreenPoint(
        mapCamera.crs.pointToLatLng(tile * tileSize, tile.z.toDouble()),
      );
      final se = mapCamera.latLngToScreenPoint(
        mapCamera.crs.pointToLatLng(
          (tile + const Point(1, 1)) * tileSize,
          tile.z.toDouble(),
        ),
      );
      final rect = Rect.fromPoints(nw.toOffset(), se.toOffset());

      /*context.canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 3,
      );*/

      final maxSubtilesCount =
          _possibleSubtilesCountPerZoomLevel[tile.z - minZoom];

      final greyscaleAmount =
          maxSubtilesCount == 0 ? 1.0 : (subtilesCount / maxSubtilesCount);

      _layerHandles.elementAt(layerHandleIndex).layer = context.pushColorFilter(
        offset,
        _grayscale(1 - greyscaleAmount),
        (context, offset) => context.pushClipRect(
          needsCompositing,
          offset,
          rect,
          (context, offset) {
            context.paintChild(child!, offset);
            //context.canvas.clipRect(Offset.zero & size);
            //context.canvas.drawColor(Colors.red, BlendMode.src);
          },
        ),
        oldLayer: _layerHandles.elementAt(layerHandleIndex).layer,
      );

      layerHandleIndex++;

      // TODO: Change to delete 100%ed tiles (recurse down towards maxzoom)
      // TODO: Combine into paths
      // TODO: Cache paths between paints unless mapcamera changed
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

    /*int rectI = 0;
    for (final rect in rects) {
      context.canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 3,
      );
      rectI++;
    }*/
  }
}
