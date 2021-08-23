/*import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/layer/tile_builder/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';

/// Options (like `TileLayerOptions`) for the `PreloadSurroundingsLayer`/`PreloadSurroundingsPlugin`
class PreloadSurroundingsOptions extends LayerOptions {
  /// The radius of the region to be loaded, excluding the original tile, to create a square region, as a number of tiles
  ///
  /// Example: the default 3 tiles will load a 7x7 square (49 tiles), with the orignal tile in the middle. (n*2+1)x(n*2+1) is the formula.
  // CUSTOM
  final int tilesAmount;

  /// Defines the structure to create the URLs for the tiles.
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String? urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions? wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  /// The max zoom applicable. In most tile providers goes from 0 to 19.
  final double maxZoom;

  final bool zoomReverse;
  final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
  final List<String> subdomains;

  ///Color shown behind the tiles.
  final Color backgroundColor;

  ///Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is CachedNetworkTileProvider,
  /// which loads tile images from network and caches them offline.
  ///
  /// If you don't want to cache the tiles, use NetworkTileProvider instead.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  ///
  final TileProvider tileProvider;

  /// Deprecated, as we try and work on a system having some sort of
  /// caching anyway now.
  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  /// final int keepBuffer;
  /// Placeholder to show until tile images are fetched by the provider.
  ImageProvider? placeholderImage;

  /// Static informations that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  ///
  Map<String, String> additionalOptions;

  /// A List of relative zoom in/out order that we try. Example [1,2,3,-1,-2]
  /// Try 3 levels of old larger tiles, then 2 levels of old smaller ones
  List backupTileExpansionStrategy;

  MapController? mapController;

  /// Creates an options object (like `TileLayerOptions`) for the `PreloadSurroundingsLayer`/`PreloadSurroundingsPlugin`
  PreloadSurroundingsOptions({
    this.tilesAmount = 3, // CUSTOM
    this.urlTemplate,
    this.tileSize = 256.0,
    this.maxZoom = 25.0,
    this.zoomReverse = false,
    this.zoomOffset = 0.0,
    this.additionalOptions = const <String, String>{},
    this.subdomains = const <String>[],
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.placeholderImage,
    this.tileProvider = const NonCachingNetworkTileProvider(),
    this.tms = false,
    this.wmsOptions,
    this.opacity = 1.0,
    this.backupTileExpansionStrategy = const [1, 2, 3, -1, -2],
    this.mapController,
    rebuild,
  }) : super(rebuild: rebuild);
}

/// The object to be added to the plugins list in the maps to use the preload surroundings functionality
class PreloadSurroundingsPlugin implements MapPlugin {
  /// A valid `PreloadSurroundingsOptions`
  final PreloadSurroundingsOptions options;

  /// Creates an object to be added to the plugins list in the maps to use the preload surroundings functionality
  PreloadSurroundingsPlugin({required this.options});

  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is PreloadSurroundingsOptions) {
      return PreloadSurroundingsLayer(options, mapState, stream);
    }

    throw UnsupportedError('Unknown options type to preload surroundings');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is PreloadSurroundingsOptions;
  }
}

class PreloadSurroundingsLayer extends StatefulWidget {
  final PreloadSurroundingsOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  PreloadSurroundingsLayer(
    this.options,
    this.mapState,
    this.stream,
  ) : super(key: options.key);

  @override
  State<StatefulWidget> createState() {
    return _PreloadSurroundingsLayerState();
  }
}

class _PreloadSurroundingsLayerState extends State<PreloadSurroundingsLayer>
    with TickerProviderStateMixin {
  MapState get map => widget.mapState;

  PreloadSurroundingsOptions get options => widget.options;
  late Bounds _globalTileRange;
  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;
  double? _tileZoom;

  //ignore: unused_field
  Level? _level;
  StreamSubscription? _moveSub;
  StreamController<LatLng?>? _throttleUpdate;
  late CustomPoint _tileSize;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  Timer? _pruneLater;

  @override
  void initState() {
    super.initState();
    _tileSize = CustomPoint(options.tileSize, options.tileSize);
    _resetView();
    _update(null);
    _moveSub = widget.stream.listen((_) => _handleMove());

    _initThrottleUpdate();
  }

  @override
  void didUpdateWidget(PreloadSurroundingsLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

    if (oldWidget.options.tileSize != options.tileSize) {
      _tileSize = CustomPoint(options.tileSize, options.tileSize);
      reloadTiles = true;
    }

    /*if (oldWidget.options.retinaMode != options.retinaMode) {
      reloadTiles = true;
    }*/

    reloadTiles |= _isZoomOutsideMinMax();

    /*if (oldWidget.options.updateInterval != options.updateInterval) {
      _throttleUpdate?.close();
      _initThrottleUpdate();
    }*/

    if (!reloadTiles) {
      final oldUrl = //oldWidget.psOptions.wmsOptions?._encodedBaseUrl ??
          oldWidget.options.urlTemplate;
      final newUrl = options.wmsOptions?._encodedBaseUrl ?? options.urlTemplate;

      final oldOptions = oldWidget.options.additionalOptions;
      final newOptions = options.additionalOptions;

      if (oldUrl != newUrl ||
          !(const MapEquality()).equals(oldOptions, newOptions)) {
        if (options.overrideTilesWhenUrlChanges) {
          for (var tile in _tiles.values) {
            tile.imageProvider = options.tileProvider
                .getImage(_wrapCoords(tile.coords), options);
            tile.loadTileImage();
          }
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _removeAllTiles();
      _resetView();
      _update(null);
    }
  }

  bool _isZoomOutsideMinMax() {
    for (var tile in _tiles.values) {
      if (tile.level.zoom > (options.maxZoom) ||
          tile.level.zoom < (options.minZoom)) {
        return true;
      }
    }
    return false;
  }

  void _initThrottleUpdate() {
    if (options.updateInterval == null) {
      _throttleUpdate = null;
    } else {
      _throttleUpdate = StreamController<LatLng?>(sync: true);
      _throttleUpdate!.stream
          .transform(
            util.throttleStreamTransformerWithTrailingCall<LatLng?>(
              options.updateInterval!,
            ),
          )
          .listen(_update);
    }
  }

  @override
  void dispose() {
    _removeAllTiles();
    _moveSub?.cancel();
    _pruneLater?.cancel();
    options.tileProvider.dispose();
    _throttleUpdate?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tilesToRender = _tiles.values.toList()..sort();

    var tileWidgets = <Widget>[
      for (var tile in tilesToRender) _createTileWidget(tile)
    ];

    var tilesContainer = Stack(
      children: tileWidgets,
    );

    return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: options.tilesContainerBuilder == null
            ? tilesContainer
            : options.tilesContainerBuilder!(
                context,
                tilesContainer,
                tilesToRender,
              ),
      ),
    );
  }

  Widget _createTileWidget(Tile tile) {
    var tilePos = tile.tilePos;
    var level = tile.level;
    var tileSize = getTileSize();
    var pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
    num width = tileSize.x * level.scale;
    num height = tileSize.y * level.scale;

    final Widget content = AnimatedTile(
      tile: tile,
      errorImage: options.errorImage,
      tileBuilder: options.tileBuilder,
    );

    return Positioned(
      key: ValueKey(tile.coordsKey),
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
      child: content,
    );
  }

  void _abortLoading() {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.coords.z != _tileZoom) {
        if (tile.loaded == null) {
          toRemove.add(entry.key);
        }
      }
    }

    for (var key in toRemove) {
      var tile = _tiles[key]!;

      tile.tileReady = null;
      tile.dispose(tile.loadError &&
          options.evictErrorTileStrategy != EvictErrorTileStrategy.none);
      _tiles.remove(key);
    }
  }

  CustomPoint getTileSize() {
    return _tileSize;
  }

  bool _hasLevelChildren(double lvl) {
    for (var tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level? _updateLevels() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var entry in _levels.entries) {
      var z = entry.key;
      var lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }

    return _level = level;
  }

  void _pruneTiles() {
    var zoom = _tileZoom;
    if (zoom == null) {
      _removeAllTiles();
      return;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      tile.retain = tile.current;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.current && !tile.active) {
        var coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeAllTiles() {
    var toRemove = Map<String, Tile>.from(_tiles);

    for (var key in toRemove.keys) {
      _removeTile(key);
    }
  }

  bool _retainParent(double x, double y, double z, double minZoom) {
    var x2 = (x / 2).floorToDouble();
    var y2 = (y / 2).floorToDouble();
    var z2 = z - 1;
    var coords2 = Coords(x2, y2);
    coords2.z = z2;

    var key = _tileCoordsToKey(coords2);

    var tile = _tiles[key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        var coords = Coords(i, j);
        coords.z = z + 1;

        var key = _tileCoordsToKey(coords);

        var tile = _tiles[key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loaded != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  double _clampZoom(double zoom) {
    if (null != options.minNativeZoom && zoom < options.minNativeZoom!) {
      return options.minNativeZoom!;
    }

    if (null != options.maxNativeZoom && options.maxNativeZoom! < zoom) {
      return options.maxNativeZoom!;
    }

    return zoom;
  }

  void _setView(LatLng center, double zoom) {
    double? tileZoom = _clampZoom(zoom.roundToDouble());
    if ((tileZoom > options.maxZoom) || (tileZoom < options.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _abortLoading();

    _updateLevels();
    _resetGrid();

    if (_tileZoom != null) {
      _update(center);
    }

    _pruneTiles();
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i]!, center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var translate = level.origin!.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first = (map.project(LatLng(0.0, crs.wrapLng!.item1), tileZoom).x /
              tileSize.x)
          .floorToDouble();
      var second = (map.project(LatLng(0.0, crs.wrapLng!.item2), tileZoom).x /
              tileSize.y)
          .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first = (map.project(LatLng(crs.wrapLat!.item1, 0.0), tileZoom).y /
              tileSize.x)
          .floorToDouble();
      var second = (map.project(LatLng(crs.wrapLat!.item2, 0.0), tileZoom).y /
              tileSize.y)
          .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  void _handleMove() {
    var tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restore fully via _setView call if we are back on trail
      if ((tileZoom <= options.maxZoom) && (tileZoom >= options.minZoom)) {
        _tileZoom = tileZoom;
        setState(() {
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        });
      }
    } else {
      setState(() {
        if ((tileZoom - _tileZoom!).abs() >= 1) {
          // It was a zoom lvl change
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        } else {
          if (_throttleUpdate == null) {
            _update(null);
          } else {
            _throttleUpdate!.add(null);
          }

          _setZoomTransforms(map.center, map.zoom);
        }
      });
    }
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    var scale = map.getZoomScale(map.zoom, _tileZoom);
    var pixelCenter = map.project(center, _tileZoom).floor();
    var halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // Private method to load tiles in the grid's active zoom level according to
  // map bounds
  void _update(LatLng? center) {
    if (_tileZoom == null) {
      return;
    }

    var zoom = _clampZoom(map.zoom);
    center ??= map.center;

    var pixelBounds = _getTiledPixelBounds(center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.center;
    final queue = <Coords<num>>[];
    var margin = options.keepBuffer;
    var noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      var c = tile.coords;

      if (tile.current == true &&
          (c.z != _tileZoom || !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }

    // _update just loads more tiles. If the tile zoom level differs too much
    // from the map's, let _setView reset levels and prune old tiles.
    if ((zoom - _tileZoom!).abs() > 1) {
      _setView(center, zoom);
      return;
    }

    // create a queue of coordinates to load tiles from
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        final coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom!;

        if (!_isValidTile(coords)) {
          continue;
        }

        var tile = _tiles[_tileCoordsToKey(coords)];
        if (tile != null) {
          tile.current = true;
        } else {
          queue.add(coords);
        }
      }
    }

    _evictErrorTilesBasedOnStrategy(tileRange);

    // sort tile queue to load tiles in order of their distance to center
    queue.sort((a, b) =>
        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());

    for (var i = 0; i < queue.length; i++) {
      _addTile(queue[i] as Coords<double>);
    }
  }

  bool _isValidTile(Coords coords) {
    var crs = map.options.crs;

    if (!crs.infinite) {
      // don't load tile if it's out of bounds and not wrapped
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  //ignore: unused_element
  Coords _keyToTileCoords(String key) {
    var k = key.split(':');
    var coords = Coords(double.parse(k[0]), double.parse(k[1]));
    coords.z = double.parse(k[2]);

    return coords;
  }

  void _removeTile(String key) {
    var tile = _tiles[key];
    if (tile == null) {
      return;
    }

    tile.dispose(tile.loadError &&
        options.evictErrorTileStrategy != EvictErrorTileStrategy.none);
    _tiles.remove(key);
  }

  void _addTile(Coords<double> coords) {
    var tileCoordsToKey = _tileCoordsToKey(coords);
    var tile = _tiles[tileCoordsToKey] = Tile(
      coords: coords,
      coordsKey: tileCoordsToKey,
      tilePos: _getTilePos(coords),
      current: true,
      level: _levels[coords.z]!,
      imageProvider:
          options.tileProvider.getImage(_wrapCoords(coords), options),
      tileReady: _tileReady,
    );

    tile.loadTileImage();
  }

  void _evictErrorTilesBasedOnStrategy(Bounds tileRange) {
    if (options.evictErrorTileStrategy ==
        EvictErrorTileStrategy.notVisibleRespectMargin) {
      var toRemove = <String>[];
      for (var entry in _tiles.entries) {
        var tile = entry.value;

        if (tile.loadError && !tile.current) {
          toRemove.add(entry.key);
        }
      }

      for (var key in toRemove) {
        var tile = _tiles[key]!;

        tile.dispose(true);
        _tiles.remove(key);
      }
    } else if (options.evictErrorTileStrategy ==
        EvictErrorTileStrategy.notVisible) {
      var toRemove = <String>[];
      for (var entry in _tiles.entries) {
        var tile = entry.value;
        var c = tile.coords;

        if (tile.loadError &&
            (!tile.current || !tileRange.contains(CustomPoint(c.x, c.y)))) {
          toRemove.add(entry.key);
        }
      }

      for (var key in toRemove) {
        var tile = _tiles[key]!;

        tile.dispose(true);
        _tiles.remove(key);
      }
    }
  }

  void _tileReady(Coords<double> coords, dynamic error, Tile? tile) {
    if (null != error) {
      print(error);

      tile!.loadError = true;

      if (options.errorTileCallback != null) {
        options.errorTileCallback!(tile, error);
      }
    } else {
      tile!.loadError = false;
    }

    var key = _tileCoordsToKey(coords);
    tile = _tiles[key];
    if (null == tile) {
      return;
    }

    if (options.fastReplace && mounted) {
      setState(() {
        tile!.active = true;

        if (_noTilesToLoad()) {
          // We're not waiting for anything, prune the tiles immediately.
          _pruneTiles();
        }
      });
      return;
    }

    var fadeInStart = tile.loaded == null
        ? options.tileFadeInStart
        : options.tileFadeInStartWhenOverride;
    tile.loaded = DateTime.now();
    if (options.tileFadeInDuration == null ||
        fadeInStart == 1.0 ||
        (tile.loadError && null == options.errorImage)) {
      tile.active = true;
    } else {
      tile.startFadeInAnimation(
        options.tileFadeInDuration!,
        this,
        from: fadeInStart,
      );
    }

    if (mounted) {
      setState(() {});
    }

    if (_noTilesToLoad()) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile
      // fade-in) to trigger a pruning.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        options.tileFadeInDuration != null
            ? options.tileFadeInDuration! + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (mounted) {
            setState(_pruneTiles);
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(Coords coords) {
    var level = _levels[coords.z as double]!;
    return coords.scaleBy(getTileSize()) - level.origin!;
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX!)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY!)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }

  bool _noTilesToLoad() {
    for (var entry in _tiles.entries) {
      if (entry.value.loaded == null) {
        return false;
      }
    }
    return true;
  }
}*/
/*
import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/layer/tile_builder/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/layer/layer.dart';

import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// Describes the needed properties to create a tile-based layer. A tile is an
/// image bound to a specific geographical position.
@experimental
class PreloadSurroundingsOptions extends LayerOptions {
  /// Defines the structure to create the URLs for the tiles. `{s}` means one of
  /// the available subdomains (can be omitted) `{z}` zoom level `{x}` and `{y}`
  /// — tile coordinates `{r}` can be used to add "&commat;2x" to the URL to
  /// load retina tiles (can be omitted)
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String? urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions? wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  // The minimum zoom level down to which this layer will be
  // displayed (inclusive).
  final double minZoom;

  /// The maximum zoom level up to which this layer will be displayed
  /// (inclusive). In most tile providers goes from 0 to 19.
  final double maxZoom;

  /// Minimum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels lower than minNativeZoom will be loaded from
  /// minNativeZoom level and auto-scaled.
  final double? minNativeZoom;

  /// Maximum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels higher than maxNativeZoom will be loaded from
  /// maxNativeZoom level and auto-scaled.
  final double? maxNativeZoom;

  /// If set to true, the zoom number used in tile URLs will be reversed
  /// (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  /// The zoom number used in tile URLs will be offset with this value.
  final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
  final List<String> subdomains;

  /// Color shown behind the tiles.
  final Color backgroundColor;

  /// Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is `NonCachingNetworkTileProvider()` which
  /// doesn't cache tiles and won't retry the HTTP request. Use `NetworkTileProvider()` for
  /// a provider which will retry requests. For the best caching implementations, see the
  /// flutter_map readme.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  ///
  final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Placeholder to show until tile images are fetched by the provider.
  final ImageProvider? placeholderImage;

  /// Tile image to show in place of the tile that failed to load.
  final ImageProvider? errorImage;

  /// Static information that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}{r}.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  ///
  final Map<String, String> additionalOptions;

  /// Tiles will not update more than once every `updateInterval` (default 200
  /// milliseconds) when panning. It can be null (but it will calculating for
  /// loading tiles every frame when panning / zooming, flutter is fast) This
  /// can save some fps and even bandwidth (ie. when fast panning / animating
  /// between long distances in short time)
  final Duration? updateInterval;

  /// Tiles fade in duration in milliseconds (default 100). This can be null to
  /// avoid fade in.
  final Duration? tileFadeInDuration;

  /// Opacity start value when Tile starts fade in (0.0 - 1.0) Takes effect if
  /// `tileFadeInDuration` is not null
  final double tileFadeInStart;

  /// Opacity start value when an exists Tile starts fade in with different Url
  /// (0.0 - 1.0) Takes effect when `tileFadeInDuration` is not null and if
  /// `overrideTilesWhenUrlChanges` if true
  final double tileFadeInStartWhenOverride;

  /// `false`: current Tiles will be first dropped and then reload via new url
  /// (default) `true`: current Tiles will be visible until new ones aren't
  /// loaded (new Tiles are loaded independently) @see
  /// https://github.com/johnpryan/flutter_map/issues/583
  final bool overrideTilesWhenUrlChanges;

  /// If `true`, it will request four tiles of half the specified size and a
  /// bigger zoom level in place of one to utilize the high resolution.
  ///
  /// If `true` then MapOptions's `maxZoom` should be `maxZoom - 1` since
  /// retinaMode just simulates retina display by playing with `zoomOffset`. If
  /// geoserver supports retina `@2` tiles then it it advised to use them
  /// instead of simulating it (use {r} in the [urlTemplate])
  ///
  /// It is advised to use retinaMode if display supports it, write code like
  /// this:
  ///
  /// ```dart
  /// TileLayerOptions(
  ///     retinaMode: true && MediaQuery.of(context).devicePixelRatio > 1.0,
  /// ),
  /// ```
  final bool retinaMode;

  /// This callback will be execute if some errors occur when fetching tiles.
  final ErrorTileCallBack? errorTileCallback;

  final TemplateFunction templateFunction;

  /// Function which may Wrap Tile with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TileBuilder? tileBuilder;

  /// Function which may wrap Tiles Container with custom Widget
  /// There are predefined examples in 'tile_builder.dart'
  final TilesContainerBuilder? tilesContainerBuilder;

  // If a Tile was loaded with error and if strategy isn't `none` then TileProvider
  // will be asked to evict Image based on current strategy
  // (see #576 - even Error Images are cached in flutter)
  final EvictErrorTileStrategy evictErrorTileStrategy;

  /// This option is useful when you have a transparent layer: rather than
  /// keeping the old layer visible when zooming (resulting in both layers
  /// being temporarily visible), the old layer is removed as quickly as
  /// possible when this is set to `true` (default `false`).
  ///
  /// This option is likely to cause some flickering of the transparent layer,
  /// most noticeable when using pinch-to-zoom. It's best used with maps that
  /// have `interactive` set to `false`, and zoom using buttons that call
  /// `MapController.move()`.
  ///
  /// When set to `true`, the `tileFadeIn*` options will be ignored.
  final bool fastReplace;

  @experimental
  PreloadSurroundingsOptions({
    Key? key,
    required this.urlTemplate,
    double tileSize = 256.0,
    double minZoom = 0.0,
    double maxZoom = 18.0,
    this.minNativeZoom,
    this.maxNativeZoom,
    this.zoomReverse = false,
    double zoomOffset = 0.0,
    Map<String, String>? additionalOptions,
    this.subdomains = const <String>[],
    this.keepBuffer = 2,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.placeholderImage,
    this.errorImage,
    this.tileProvider = const NonCachingNetworkTileProvider(),
    this.tms = false,
    this.wmsOptions,
    this.opacity = 1.0,
    // Tiles will not update more than once every `updateInterval` milliseconds
    // (default 200) when panning. It can be 0 (but it will calculating for
    // loading tiles every frame when panning / zooming, flutter is fast) This
    // can save some fps and even bandwidth (ie. when fast panning / animating
    // between long distances in short time)
    this.updateInterval = const Duration(milliseconds: 200),
    // Tiles fade in duration in milliseconds (default 100).  This can be set to
    // 0 to avoid fade in
    this.tileFadeInDuration = const Duration(milliseconds: 100),
    this.tileFadeInStart = 0.0,
    this.tileFadeInStartWhenOverride = 0.0,
    this.overrideTilesWhenUrlChanges = false,
    this.retinaMode = false,
    this.errorTileCallback,
    Stream<Null>? rebuild,
    this.templateFunction = util.template,
    this.tileBuilder,
    this.tilesContainerBuilder,
    this.evictErrorTileStrategy = EvictErrorTileStrategy.none,
    this.fastReplace = false,
  })  : assert(tileFadeInStart >= 0.0 && tileFadeInStart <= 1.0),
        assert(tileFadeInStartWhenOverride >= 0.0 &&
            tileFadeInStartWhenOverride <= 1.0),
        maxZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && !zoomReverse
                ? maxZoom - 1.0
                : maxZoom,
        minZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && zoomReverse
                ? math.max(minZoom + 1.0, 0.0)
                : minZoom,
        zoomOffset = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (zoomReverse ? zoomOffset - 1.0 : zoomOffset + 1.0)
            : zoomOffset,
        tileSize = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (tileSize / 2.0).floorToDouble()
            : tileSize,
        // copy additionalOptions Map if not null, so we can safely compare old
        // and new Map inside didUpdateWidget with MapEquality.
        additionalOptions = additionalOptions == null
            ? const <String, String>{}
            : Map.from(additionalOptions),
        super(key: key, rebuild: rebuild);
}

class PreloadSurroundingsWidget extends StatelessWidget {
  final PreloadSurroundingsOptions options;

  PreloadSurroundingsWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;

    return PreloadSurroundingsLayer(
      mapState: mapState,
      stream: mapState.onMoved,
      options: options,
    );
  }
}

@experimental
class PreloadSurroundingsLayer extends StatefulWidget {
  final PreloadSurroundingsOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  PreloadSurroundingsLayer({
    required this.options,
    required this.mapState,
    required this.stream,
  }) : super(key: options.key);

  @override
  State<StatefulWidget> createState() {
    return _PreloadSurroundingsLayerState();
  }
}

class _PreloadSurroundingsLayerState extends State<PreloadSurroundingsLayer>
    with TickerProviderStateMixin {
  MapState get map => widget.mapState;

  PreloadSurroundingsOptions get options => widget.options;
  late Bounds _globalTileRange;
  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;
  double? _tileZoom;

  //ignore: unused_field
  Level? _level;
  StreamSubscription? _moveSub;
  StreamController<LatLng?>? _throttleUpdate;
  late CustomPoint _tileSize;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  Timer? _pruneLater;

  @override
  void initState() {
    super.initState();
    _tileSize = CustomPoint(options.tileSize, options.tileSize);
    _resetView();
    _update(null);
    _moveSub = widget.stream.listen((_) => _handleMove());

    _initThrottleUpdate();
  }

  @override
  void didUpdateWidget(PreloadSurroundingsLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

    if (oldWidget.options.tileSize != options.tileSize) {
      _tileSize = CustomPoint(options.tileSize, options.tileSize);
      reloadTiles = true;
    }

    if (oldWidget.options.retinaMode != options.retinaMode) {
      reloadTiles = true;
    }

    reloadTiles |= _isZoomOutsideMinMax();

    if (oldWidget.options.updateInterval != options.updateInterval) {
      _throttleUpdate?.close();
      _initThrottleUpdate();
    }

    if (!reloadTiles) {
      final oldUrl = //oldWidget.options.wmsOptions?._encodedBaseUrl ??
          oldWidget.options.urlTemplate;
      final newUrl = /*options.wmsOptions?._encodedBaseUrl ??*/ options
          .urlTemplate;

      final oldOptions = oldWidget.options.additionalOptions;
      final newOptions = options.additionalOptions;

      if (oldUrl != newUrl ||
          !(const MapEquality()).equals(oldOptions, newOptions)) {
        if (options.overrideTilesWhenUrlChanges) {
          for (var tile in _tiles.values) {
            tile.imageProvider = options.tileProvider
                .getImage(_wrapCoords(tile.coords), options);
            tile.loadTileImage();
          }
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _removeAllTiles();
      _resetView();
      _update(null);
    }
  }

  bool _isZoomOutsideMinMax() {
    for (var tile in _tiles.values) {
      if (tile.level.zoom > (options.maxZoom) ||
          tile.level.zoom < (options.minZoom)) {
        return true;
      }
    }
    return false;
  }

  void _initThrottleUpdate() {
    if (options.updateInterval == null) {
      _throttleUpdate = null;
    } else {
      _throttleUpdate = StreamController<LatLng?>(sync: true);
      _throttleUpdate!.stream
          .transform(
            util.throttleStreamTransformerWithTrailingCall<LatLng?>(
              options.updateInterval!,
            ),
          )
          .listen(_update);
    }
  }

  @override
  void dispose() {
    _removeAllTiles();
    _moveSub?.cancel();
    _pruneLater?.cancel();
    options.tileProvider.dispose();
    _throttleUpdate?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tilesToRender = _tiles.values.toList()..sort();

    var tileWidgets = <Widget>[
      for (var tile in tilesToRender) _createTileWidget(tile)
    ];

    var tilesContainer = Stack(
      children: tileWidgets,
    );

    return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: options.tilesContainerBuilder == null
            ? tilesContainer
            : options.tilesContainerBuilder!(
                context,
                tilesContainer,
                tilesToRender,
              ),
      ),
    );
  }

  Widget _createTileWidget(Tile tile) {
    var tilePos = tile.tilePos;
    var level = tile.level;
    var tileSize = getTileSize();
    var pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
    num width = tileSize.x * level.scale;
    num height = tileSize.y * level.scale;

    final Widget content = AnimatedTile(
      tile: tile,
      errorImage: options.errorImage,
      tileBuilder: options.tileBuilder,
    );

    return Positioned(
      key: ValueKey(tile.coordsKey),
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
      child: content,
    );
  }

  void _abortLoading() {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.coords.z != _tileZoom) {
        if (tile.loaded == null) {
          toRemove.add(entry.key);
        }
      }
    }

    for (var key in toRemove) {
      var tile = _tiles[key]!;

      tile.tileReady = null;
      tile.dispose(tile.loadError &&
          options.evictErrorTileStrategy != EvictErrorTileStrategy.none);
      _tiles.remove(key);
    }
  }

  CustomPoint getTileSize() {
    return _tileSize;
  }

  bool _hasLevelChildren(double lvl) {
    for (var tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level? _updateLevels() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var entry in _levels.entries) {
      var z = entry.key;
      var lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }

    return _level = level;
  }

  void _pruneTiles() {
    var zoom = _tileZoom;
    if (zoom == null) {
      _removeAllTiles();
      return;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      tile.retain = tile.current;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.current && !tile.active) {
        var coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeAllTiles() {
    var toRemove = Map<String, Tile>.from(_tiles);

    for (var key in toRemove.keys) {
      _removeTile(key);
    }
  }

  bool _retainParent(double x, double y, double z, double minZoom) {
    var x2 = (x / 2).floorToDouble();
    var y2 = (y / 2).floorToDouble();
    var z2 = z - 1;
    var coords2 = Coords(x2, y2);
    coords2.z = z2;

    var key = _tileCoordsToKey(coords2);

    var tile = _tiles[key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        var coords = Coords(i, j);
        coords.z = z + 1;

        var key = _tileCoordsToKey(coords);

        var tile = _tiles[key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loaded != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  double _clampZoom(double zoom) {
    if (null != options.minNativeZoom && zoom < options.minNativeZoom!) {
      return options.minNativeZoom!;
    }

    if (null != options.maxNativeZoom && options.maxNativeZoom! < zoom) {
      return options.maxNativeZoom!;
    }

    return zoom;
  }

  void _setView(LatLng center, double zoom) {
    double? tileZoom = _clampZoom(zoom.roundToDouble());
    if ((tileZoom > options.maxZoom) || (tileZoom < options.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _abortLoading();

    _updateLevels();
    _resetGrid();

    if (_tileZoom != null) {
      _update(center);
    }

    _pruneTiles();
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i]!, center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var translate = level.origin!.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first = (map.project(LatLng(0.0, crs.wrapLng!.item1), tileZoom).x /
              tileSize.x)
          .floorToDouble();
      var second = (map.project(LatLng(0.0, crs.wrapLng!.item2), tileZoom).x /
              tileSize.y)
          .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first = (map.project(LatLng(crs.wrapLat!.item1, 0.0), tileZoom).y /
              tileSize.x)
          .floorToDouble();
      var second = (map.project(LatLng(crs.wrapLat!.item2, 0.0), tileZoom).y /
              tileSize.y)
          .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  void _handleMove() {
    var tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restore fully via _setView call if we are back on trail
      if ((tileZoom <= options.maxZoom) && (tileZoom >= options.minZoom)) {
        _tileZoom = tileZoom;
        setState(() {
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        });
      }
    } else {
      setState(() {
        if ((tileZoom - _tileZoom!).abs() >= 1) {
          // It was a zoom lvl change
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        } else {
          if (_throttleUpdate == null) {
            _update(null);
          } else {
            _throttleUpdate!.add(null);
          }

          _setZoomTransforms(map.center, map.zoom);
        }
      });
    }
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    var scale = map.getZoomScale(map.zoom, _tileZoom);
    var pixelCenter = map.project(center, _tileZoom).floor();
    var halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // Private method to load tiles in the grid's active zoom level according to
  // map bounds
  void _update(LatLng? center) {
    if (_tileZoom == null) {
      return;
    }

    var zoom = _clampZoom(map.zoom);
    center ??= map.center;

    var pixelBounds = _getTiledPixelBounds(center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.center;
    final queue = <Coords<num>>[];
    var margin = options.keepBuffer;
    var noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      var c = tile.coords;

      if (tile.current == true &&
          (c.z != _tileZoom || !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }

    // _update just loads more tiles. If the tile zoom level differs too much
    // from the map's, let _setView reset levels and prune old tiles.
    if ((zoom - _tileZoom!).abs() > 1) {
      _setView(center, zoom);
      return;
    }

    // create a queue of coordinates to load tiles from
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        final coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom!;

        if (!_isValidTile(coords)) {
          continue;
        }

        var tile = _tiles[_tileCoordsToKey(coords)];
        if (tile != null) {
          tile.current = true;
        } else {
          queue.add(coords);
        }
      }
    }

    _evictErrorTilesBasedOnStrategy(tileRange);

    // sort tile queue to load tiles in order of their distance to center
    queue.sort((a, b) =>
        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());

    for (var i = 0; i < queue.length; i++) {
      _addTile(queue[i] as Coords<double>);
    }
  }

  bool _isValidTile(Coords coords) {
    var crs = map.options.crs;

    if (!crs.infinite) {
      // don't load tile if it's out of bounds and not wrapped
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  //ignore: unused_element
  Coords _keyToTileCoords(String key) {
    var k = key.split(':');
    var coords = Coords(double.parse(k[0]), double.parse(k[1]));
    coords.z = double.parse(k[2]);

    return coords;
  }

  void _removeTile(String key) {
    var tile = _tiles[key];
    if (tile == null) {
      return;
    }

    tile.dispose(tile.loadError &&
        options.evictErrorTileStrategy != EvictErrorTileStrategy.none);
    _tiles.remove(key);
  }

  void _addTile(Coords<double> coords) {
    var tileCoordsToKey = _tileCoordsToKey(coords);
    var tile = _tiles[tileCoordsToKey] = Tile(
      coords: coords,
      coordsKey: tileCoordsToKey,
      tilePos: _getTilePos(coords),
      current: true,
      level: _levels[coords.z]!,
      imageProvider:
          options.tileProvider.getImage(_wrapCoords(coords), options),
      tileReady: _tileReady,
    );

    tile.loadTileImage();
  }

  void _evictErrorTilesBasedOnStrategy(Bounds tileRange) {
    if (options.evictErrorTileStrategy ==
        EvictErrorTileStrategy.notVisibleRespectMargin) {
      var toRemove = <String>[];
      for (var entry in _tiles.entries) {
        var tile = entry.value;

        if (tile.loadError && !tile.current) {
          toRemove.add(entry.key);
        }
      }

      for (var key in toRemove) {
        var tile = _tiles[key]!;

        tile.dispose(true);
        _tiles.remove(key);
      }
    } else if (options.evictErrorTileStrategy ==
        EvictErrorTileStrategy.notVisible) {
      var toRemove = <String>[];
      for (var entry in _tiles.entries) {
        var tile = entry.value;
        var c = tile.coords;

        if (tile.loadError &&
            (!tile.current || !tileRange.contains(CustomPoint(c.x, c.y)))) {
          toRemove.add(entry.key);
        }
      }

      for (var key in toRemove) {
        var tile = _tiles[key]!;

        tile.dispose(true);
        _tiles.remove(key);
      }
    }
  }

  void _tileReady(Coords<double> coords, dynamic error, Tile? tile) {
    if (null != error) {
      print(error);

      tile!.loadError = true;

      if (options.errorTileCallback != null) {
        options.errorTileCallback!(tile, error);
      }
    } else {
      tile!.loadError = false;
    }

    var key = _tileCoordsToKey(coords);
    tile = _tiles[key];
    if (null == tile) {
      return;
    }

    if (options.fastReplace && mounted) {
      setState(() {
        tile!.active = true;

        if (_noTilesToLoad()) {
          // We're not waiting for anything, prune the tiles immediately.
          _pruneTiles();
        }
      });
      return;
    }

    var fadeInStart = tile.loaded == null
        ? options.tileFadeInStart
        : options.tileFadeInStartWhenOverride;
    tile.loaded = DateTime.now();
    if (options.tileFadeInDuration == null ||
        fadeInStart == 1.0 ||
        (tile.loadError && null == options.errorImage)) {
      tile.active = true;
    } else {
      tile.startFadeInAnimation(
        options.tileFadeInDuration!,
        this,
        from: fadeInStart,
      );
    }

    if (mounted) {
      setState(() {});
    }

    if (_noTilesToLoad()) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile
      // fade-in) to trigger a pruning.
      _pruneLater?.cancel();
      _pruneLater = Timer(
        options.tileFadeInDuration != null
            ? options.tileFadeInDuration! + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (mounted) {
            setState(_pruneTiles);
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(Coords coords) {
    var level = _levels[coords.z as double]!;
    return coords.scaleBy(getTileSize()) - level.origin!;
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX!)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY!)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }

  bool _noTilesToLoad() {
    for (var entry in _tiles.entries) {
      if (entry.value.loaded == null) {
        return false;
      }
    }
    return true;
  }
}*/
