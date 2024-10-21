part of '../download_progress_masker.dart';

class GreyscaleMasker extends SingleChildRenderObjectWidget {
  const GreyscaleMasker({
    super.key,
    required super.child,
    required this.latestTileCoordinates,
    required this.mapCamera,
    required this.minZoom,
    required this.maxZoom,
    required this.tileSize,
  });

  final TileCoordinates? latestTileCoordinates;
  final MapCamera mapCamera;
  final int minZoom;
  final int maxZoom;
  final int tileSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _GreyscaleMaskerRenderer(
        mapCamera: mapCamera,
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
    if (latestTileCoordinates case final ltc?) renderObject.addTile(ltc);
    // We don't support changing the other properties. They should not change
    // during a download.
  }
}

class _GreyscaleMaskerRenderer extends RenderProxyBox {
  _GreyscaleMaskerRenderer({
    required MapCamera mapCamera,
    required this.minZoom,
    required this.maxZoom,
    required this.tileSize,
  })  : assert(
          maxZoom - minZoom < 32,
          'Unable to work with the large numbers that result from handling the '
          'difference of `maxZoom` & `minZoom`',
        ),
        _mapCamera = mapCamera {
    // Precalculate for more efficient greyscale amount calculations later
    _maxSubtilesCountPerZoomLevel = Uint64List((maxZoom - minZoom) + 1);
    int p = 0;
    for (int i = minZoom; i < maxZoom; i++) {
      _maxSubtilesCountPerZoomLevel[p] = pow(4, maxZoom - i).toInt();
      p++;
    }
    _maxSubtilesCountPerZoomLevel[p] = 0;
  }

  //! PROPERTIES

  MapCamera _mapCamera;
  MapCamera get mapCamera => _mapCamera;
  set mapCamera(MapCamera value) {
    if (value == mapCamera) return;
    _mapCamera = value;
    _recompileGreyscalePathCache();
    markNeedsPaint();
  }

  TileCoordinates? _prevTile;

  /// Minimum zoom level of the download
  ///
  /// The difference of [maxZoom] & [minZoom] must be less than 32, due to
  /// limitations with 64-bit integers.
  final int minZoom;

  /// Maximum zoom level of the download
  ///
  /// The difference of [maxZoom] & [minZoom] must be less than 32, due to
  /// limitations with 64-bit integers.
  final int maxZoom;

  /// Size of each tile in pixels
  final int tileSize;

  //! STATE

  /// Stream subscription for input `tileCoordinates` stream
  late final StreamSubscription<TileCoordinates> _tileCoordinatesSub;

  /// Maps tiles of a download to a [_TileMappingValue], which contains:
  ///  * the number of subtiles downloaded
  ///  * the lat/lng coordinates of the tile's top-left (North-West) &
  ///    bottom-left (South-East) corners, which is cached to improve
  ///    performance when re-projecting to screen space
  ///
  /// Due to the multi-threaded nature of downloading, it is important to note
  /// when modifying this map that the root tile may not yet be registered in
  /// the map if it has been queued for another thread. In this case, the value
  /// should be initialised to 0, then the thread which eventually downloads the
  /// root tile should increment the value. With the exception of this case, the
  /// existence of a tile key is an indication that that parent tile has been
  /// downloaded.
  final Map<TileCoordinates, _TileMappingValue> _tileMapping = SplayTreeMap(
    (a, b) => a.z.compareTo(b.z) | a.x.compareTo(b.x) | a.y.compareTo(b.y),
  );

  /// The number of subtiles a tile at the zoom level (index) may have
  late final Uint64List _maxSubtilesCountPerZoomLevel;

  /// Cache for a greyscale amount to the path that should be painted with that
  /// greyscale level
  ///
  /// The key is multiplied by 1/[_greyscaleLevelsCount] to give the greyscale
  /// percentage. This means there are [_greyscaleLevelsCount] levels of
  /// greyscale available. Because the difference between close greyscales is
  /// very difficult to percieve with the eye, this is acceptable, and improves
  /// performance drastically. The ideal amount is calculated and rounded to the
  /// nearest level.
  final Map<int, Path> _greyscalePathCache = Map.unmodifiable({
    for (int i = 0; i <= _greyscaleLevelsCount; i++) i: Path(),
  });
  static const _greyscaleLevelsCount = 25;

  @override
  void dispose() {
    _tileCoordinatesSub.cancel();
    super.dispose();
  }

  //! GREYSCALE HANDLING

  /// Calculate the grayscale color filter given a percentage
  ///
  /// 1 is fully greyscale, 0 is fully original color.
  ///
  /// From https://www.w3.org/TR/filter-effects-1/#grayscaleEquivalent.
  static ColorFilter _generateGreyscaleFilter(double percentage) {
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

  /// Calculate the greyscale level given the number of subtiles actually
  /// downloaded and the possible number of subtiles
  ///
  /// Multiply by 1/[_greyscaleLevelsCount] to pass to [_generateGreyscaleFilter]
  /// to generate [ColorFilter].
  int _calculateGreyscaleLevel(int subtilesCount, int maxSubtilesCount) {
    assert(
      subtilesCount <= maxSubtilesCount,
      '`subtilesCount` must be less than or equal to `maxSubtilesCount`',
    );

    final invGreyscalePercentage =
        (subtilesCount + 1) / (maxSubtilesCount + 1); // +1 to count self
    return _greyscaleLevelsCount -
        (invGreyscalePercentage * _greyscaleLevelsCount).round();
  }

  //! INPUT STREAM HANDLING

  /// Recursively work towards the root tile at the [absMinZoom] (usually
  /// [minZoom]) given a [tile]
  ///
  /// [zoomLevelCallback] is invoked with the tile at each recursed zoom level,
  /// including the original and [absMinZoom] level.
  ///
  /// In general we recurse towards the root tile because the download occurs
  /// from the root tile towards the leaf tiles.
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

  /// Project specified coordinates to a screen space [Rect]
  Rect _calculateRectOfCoords(LatLng nwCoord, LatLng seCoord) {
    final nwScreen = mapCamera.latLngToScreenPoint(nwCoord);
    final seScreen = mapCamera.latLngToScreenPoint(seCoord);
    return Rect.fromPoints(nwScreen.toOffset(), seScreen.toOffset());
  }

  /// Handles incoming tiles from the input stream, modifying the [_tileMapping]
  /// and [_greyscalePathCache] as necessary
  ///
  /// Tiles are pruned from the tile mapping where the parent tile has maxed out
  /// the number of subtiles (ie. all this tile's neighbours within the quad of
  /// the parent are also downloaded), to save memory space. However, it is
  /// not possible to prune the path cache, so this will slowly become
  /// out-of-sync and less efficient. See [_recompileGreyscalePathCache]
  /// for details.
  void addTile(TileCoordinates tile) {
    assert(tile.z >= minZoom, 'Incoming `tile` has zoom level below minimum');
    assert(tile.z <= maxZoom, 'Incoming `tile` has zoom level above maximum');

    if (tile == _prevTile) return;
    _prevTile = tile;

    _recurseTileToMinZoomLevelParentWithCallback(
      tile,
      minZoom,
      (intermediateZoomTile) {
        final maxSubtilesCount =
            _maxSubtilesCountPerZoomLevel[intermediateZoomTile.z - minZoom];

        final _TileMappingValue tmv;
        if (_tileMapping[intermediateZoomTile] case final existingTMV?) {
          assert(
            existingTMV.subtilesCount < maxSubtilesCount,
            'Existing subtiles count must be smaller than max subtiles count '
            '($intermediateZoomTile: ${existingTMV.subtilesCount} !< '
            '$maxSubtilesCount)',
          );

          existingTMV.subtilesCount += 1;
          tmv = existingTMV;
        } else {
          final zoom = tile.z.toDouble();
          _tileMapping[intermediateZoomTile] = tmv = _TileMappingValue.newTile(
            nwCoord: mapCamera.crs.pointToLatLng(tile * tileSize, zoom),
            seCoord: mapCamera.crs
                .pointToLatLng((tile + const Point(1, 1)) * tileSize, zoom),
          );
        }

        _greyscalePathCache[
                _calculateGreyscaleLevel(tmv.subtilesCount, maxSubtilesCount)]!
            .addRect(_calculateRectOfCoords(tmv.nwCoord, tmv.seCoord));

        late final isParentMaxedOut = _tileMapping[TileCoordinates(
              intermediateZoomTile.x ~/ 2,
              intermediateZoomTile.y ~/ 2,
              intermediateZoomTile.z - 1,
            )]
                ?.subtilesCount ==
            _maxSubtilesCountPerZoomLevel[
                    intermediateZoomTile.z - 1 - minZoom] -
                1;
        if (intermediateZoomTile.z != minZoom && isParentMaxedOut) {
          _tileMapping.remove(intermediateZoomTile); // self

          if (intermediateZoomTile.x.isOdd) {
            _tileMapping.remove(
              TileCoordinates(
                intermediateZoomTile.x - 1,
                intermediateZoomTile.y,
                intermediateZoomTile.z,
              ),
            );
          }
          if (intermediateZoomTile.y.isOdd) {
            _tileMapping.remove(
              TileCoordinates(
                intermediateZoomTile.x,
                intermediateZoomTile.y - 1,
                intermediateZoomTile.z,
              ),
            );
          }
          if (intermediateZoomTile.x.isOdd && intermediateZoomTile.y.isOdd) {
            _tileMapping.remove(
              TileCoordinates(
                intermediateZoomTile.x - 1,
                intermediateZoomTile.y - 1,
                intermediateZoomTile.z,
              ),
            );
          }
        }
      },
    );

    markNeedsPaint();
  }

  /// Recompile the [_greyscalePathCache] ready for repainting based on the
  /// single source-of-truth of the [_tileMapping]
  ///
  /// ---
  ///
  /// To avoid mutating the cache directly, for performance, we simply reset
  /// all paths, which has the same effect but with less work.
  ///
  /// Then, for every tile, we calculate its greyscale level using its subtiles
  /// count and the maximum number of subtiles in its zoom level, and add to
  /// that level's `Path` the new rect.
  ///
  /// The lat/lng coords for the tile are cached and so do not need to be
  /// recalculated. They only need to be reprojected to screen space to handle
  /// changes to the map camera. This is more performant.
  ///
  /// We do not ever need to recurse towards the maximum zoom level. We go in
  /// order from highest to lowest zoom level when painting, and if a tile at
  /// the highest zoom level is fully downloaded (maxed subtiles), then all
  /// subtiles will be 0% greyscale anyway, when this tile is painted at 0%
  /// greyscale, so we can save unnecessary painting steps.
  ///
  /// Therefore, it is likely more efficient to paint after running this method
  /// than after a series of incoming tiles have been handled (as [addTile]
  /// cannot prune the path cache, only the tile mapping).
  ///
  /// This method does not call [markNeedsPaint], the caller should perform that
  /// if necessary.
  void _recompileGreyscalePathCache() {
    for (final path in _greyscalePathCache.values) {
      path.reset();
    }

    for (int i = _tileMapping.length - 1; i >= 0; i--) {
      final MapEntry(key: tile, value: tmv) = _tileMapping.entries.elementAt(i);

      _greyscalePathCache[_calculateGreyscaleLevel(
        tmv.subtilesCount,
        _maxSubtilesCountPerZoomLevel[tile.z - minZoom],
      )]!
          .addRect(_calculateRectOfCoords(tmv.nwCoord, tmv.seCoord));
    }
  }

  //! PAINTING

  /// Generate fresh layer handles lazily, as many as is needed
  ///
  /// Required to allow the child to be painted multiple times.
  final _layerHandles = Iterable.generate(
    double.maxFinite.toInt(),
    (_) => LayerHandle<ColorFilterLayer>(),
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint the map in greyscale
    context.pushColorFilter(
      offset,
      _generateGreyscaleFilter(1),
      (context, offset) => context.paintChild(child!, offset),
    );

    // Then paint, from colorest to greyscalist (high to low zoom level), each
    // layer using the respective `Path` as a clip ('cut')
    int layerHandleIndex = 0;
    for (int i = _greyscalePathCache.length - 1; i >= 0; i--) {
      final MapEntry(key: greyscaleAmount, value: path) =
          _greyscalePathCache.entries.elementAt(i);

      final greyscalePercentage = greyscaleAmount * 1 / 25;

      _layerHandles.elementAt(layerHandleIndex).layer = context.pushColorFilter(
        offset,
        _generateGreyscaleFilter(greyscalePercentage),
        (context, offset) => context.pushClipPath(
          needsCompositing,
          offset,
          Offset.zero & size,
          path,
          (context, offset) {
            context.paintChild(child!, offset);
            /*context.canvas.clipRect(Offset.zero & size);
            context.canvas.drawColor(
              Colors.green,
              BlendMode.hue,
            );*/
          },
          clipBehavior: Clip.hardEdge,
        ),
        oldLayer: _layerHandles.elementAt(layerHandleIndex).layer,
      );

      layerHandleIndex++;
    }
  }
}

/// See [_GreyscaleMaskerRenderer._tileMapping] for documentation
///
/// Is mutable to improve performance.
class _TileMappingValue {
  _TileMappingValue.newTile({
    required this.nwCoord,
    required this.seCoord,
  }) : subtilesCount = 0;

  int subtilesCount;

  final LatLng nwCoord;
  final LatLng seCoord;
}
