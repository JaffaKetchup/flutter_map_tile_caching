import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import 'tile_storage_caching_manager.dart';

///Provider that persist loaded raster tiles inside local sqlite db
/// [cachedValidDuration] - valid time period since [DateTime.now]
/// which determines the need for a request for remote tile server. Default value
/// is one day, that means - all cached tiles today and day before don't need rewriting.
class StorageCachingTileProvider extends TileProvider {
  static final kMaxPreloadTileAreaCount = 20000;
  final Duration cachedValidDuration;

  StorageCachingTileProvider(
      {this.cachedValidDuration = const Duration(days: 31)});

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final tileUrl = getTileUrl(coords, options);
    return CachedTileImageProvider(
        tileUrl, Coords<num>(coords.x, coords.y)..z = coords.z);
  }

  /// Caching tile area by provided [bounds], zoom edges and [options].
  /// The maximum number of tiles to load is [kMaxPreloadTileAreaCount].
  /// To check tiles number before calling this method, use
  /// [approximateTileAmount].
  /// Return [Tuple3] with number of downloaded tiles as [Tuple3.item1],
  /// number of errored tiles as [Tuple3.item2], and number of total tiles that need to be downloaded as [Tuple3.item3]
  Stream<Tuple3<int, int, int>> loadTiles(
      LatLngBounds bounds, int minZoom, int maxZoom, TileLayerOptions options,
      {Function(dynamic)? errorHandler}) async* {
    final tilesRange = approximateTileRange(
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileSize: CustomPoint(options.tileSize, options.tileSize));
    assert(tilesRange.length <= kMaxPreloadTileAreaCount,
        '${tilesRange.length} exceeds maximum number of pre-cacheable tiles');
    var errorsCount = 0;
    var client = http.Client();
    for (var i = 0; i < tilesRange.length; i++) {
      try {
        final cord = tilesRange[i];
        final cordDouble = Coords(cord.x.toDouble(), cord.y.toDouble());
        cordDouble.z = cord.z.toDouble();
        final url = getTileUrl(cordDouble, options);
        final bytes = (await client.get(Uri.parse(url))).bodyBytes;
        await TileStorageCachingManager.saveTile(bytes, cord);
      } catch (e) {
        errorsCount++;
        if (errorHandler != null) errorHandler(e);
      }
      yield Tuple3(i + 1, errorsCount, tilesRange.length);
    }
    client.close();
  }

  ///Get approximate tile amount from bounds and zoom edges.
  ///[crs] and [tileSize] is optional.
  static int approximateTileAmount(
      {required LatLngBounds bounds,
      required int minZoom,
      required int maxZoom,
      Crs crs = const Epsg3857(),
      tileSize = const CustomPoint(256, 256)}) {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    var amount = 0;
    for (var zoomLevel in List<int>.generate(
        maxZoom - minZoom + 1, (index) => index + minZoom)) {
      final nwPoint = crs
          .latLngToPoint(bounds.northWest, zoomLevel.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final sePoint = crs
              .latLngToPoint(bounds.southEast, zoomLevel.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      final a = sePoint.x - nwPoint.x + 1;
      final b = sePoint.y - nwPoint.y + 1;
      amount += a * b as int;
    }
    return amount;
  }

  ///Get tileRange from bounds and zoom edges.
  ///[crs] and [tileSize] is optional.
  static List<Coords> approximateTileRange(
      {required LatLngBounds bounds,
      required int minZoom,
      required int maxZoom,
      Crs crs = const Epsg3857(),
      tileSize = const CustomPoint(256, 256)}) {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    final cords = <Coords>[];
    for (var zoomLevel in List<int>.generate(
        maxZoom - minZoom + 1, (index) => index + minZoom)) {
      final nwPoint = crs
          .latLngToPoint(bounds.northWest, zoomLevel.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final sePoint = crs
              .latLngToPoint(bounds.southEast, zoomLevel.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      for (var x = nwPoint.x; x <= sePoint.x; x++) {
        for (var y = nwPoint.y; y <= sePoint.y; y++) {
          cords.add(Coords(x, y)..z = zoomLevel);
        }
      }
    }
    return cords;
  }
}

class CachedTileImageProvider extends ImageProvider<Coords<num>> {
  final Function(dynamic)? netWorkErrorHandler;
  final String url;
  final Coords<num> coords;
  final Duration cacheValidDuration;

  CachedTileImageProvider(this.url, this.coords,
      {this.cacheValidDuration = const Duration(days: 1),
      this.netWorkErrorHandler});

  @override
  ImageStreamCompleter load(Coords<num> key, decode) =>
      MultiFrameImageStreamCompleter(
          codec: _loadAsync(),
          scale: 1,
          informationCollector: () sync* {
            yield DiagnosticsProperty<ImageProvider>('Image provider', this);
            yield DiagnosticsProperty<Coords>('Image key', key);
          });

  @override
  Future<Coords<num>> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(coords);

  Future<Codec> _loadAsync() async {
    final localBytes = await TileStorageCachingManager.getTile(coords);
    var bytes = localBytes?.item1;
    if ((DateTime.now().millisecondsSinceEpoch -
            (localBytes?.item2.millisecondsSinceEpoch ?? 0)) >
        cacheValidDuration.inMilliseconds) {
      try {
        bytes = (await http.get(Uri.parse(url))).bodyBytes;
        await TileStorageCachingManager.saveTile(bytes, coords);
      } catch (e) {
        if (netWorkErrorHandler != null) netWorkErrorHandler!(e);
      }
    }
    if (bytes == null) {
      return Future<Codec>.error('Failed to load tile for coords: $coords');
    }
    return await PaintingBinding.instance!.instantiateImageCodec(bytes);
  }
}
