import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:flutter_map_tile_caching/src/regions/downloadableRegion.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import 'tile_storage_caching_manager.dart';

extension LatLngConversions on LatLng {
  Coords<num> toCoords(num zoomLvl) {
    return Coords(this.latitude, this.longitude)..z = zoomLvl;
  }
}

extension StringExts on String {
  void printWrapped([int consoleLimit = 1023]) {
    final pattern = new RegExp('.{1,$consoleLimit}');
    pattern.allMatches(this).forEach((match) => print(match.group(0)));
  }
}

double asinh(double value) {
  // asinh(x) = Sign(x) * ln(|x| + sqrt(x*x + 1))
  // if |x| > huge, asinh(x) ~= Sign(x) * ln(2|x|)

  if (value.abs() >= 268435456.0) // 2^28, taken from freeBSD
    return value.sign * (math.log(value.abs()) + math.log(2.0));

  return value.sign * math.log(value.abs() + math.sqrt((value * value) + 1));
}

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

  Stream<Tuple3<int, int, int>> downloadRegion(DownloadableRegion region) {
    if (region.type == RegionType.circle) {
      _downloadCircle(
        region.points,
        region.minZoom,
        region.maxZoom,
        region.options,
        errorHandler: region.errorHandler,
      );
    } else if (region.type == RegionType.square) {
      throw UnimplementedError();
    } else if (region.type == RegionType.line) {
      throw UnimplementedError();
    } else if (region.type == RegionType.customPolygon) {
      throw UnimplementedError();
    } else {
      throw UnimplementedError(
          'RegionType doesn\'t exist, and a DownloadableRegion with this type should be impossible to create if using this library correctly. Please leave a GitHub issue.');
    }
    throw UnimplementedError();
  }

  /*Stream<Tuple3<int, int, int>>*/ void _downloadCircle(
    List<LatLng> circleOutline,
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    Function(dynamic)? errorHandler,
  }) /* async* */ async {
    /*final tilesRange = approximateTileRange(
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileSize: CustomPoint(options.tileSize, options.tileSize));
    assert(tilesRange.length <= kMaxPreloadTileAreaCount,
        '${tilesRange.length} exceeds maximum number of pre-cacheable tiles');*/
    //var errorsCount = 0;
    final Map<int, Map<int, List<int>>> outlineTileNums = {};
    //int tmpCount = 0;
    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};
      final http.Client client = http.Client();

      for (LatLng node in circleOutline) {
        final double n = math.pow(2, zoomLvl).toDouble();
        final int x = ((node.longitude + 180.0) / 360.0 * n).toInt();
        final int y =
            ((1.0 - asinh(math.tan(node.latitudeInRad)) / math.pi) / 2.0 * n)
                .toInt();

        if (outlineTileNums[zoomLvl]![x] == null) {
          outlineTileNums[zoomLvl]![x] = [
            999999999999999999,
            -999999999999999999
          ];
        }

        outlineTileNums[zoomLvl]![x] = [
          y < (outlineTileNums[zoomLvl]![x]![0])
              ? y
              : (outlineTileNums[zoomLvl]![x]![0]),
          y > (outlineTileNums[zoomLvl]![x]![1])
              ? y
              : (outlineTileNums[zoomLvl]![x]![1]),
        ];

        /*outlineTileNums[zoomLvl]!.add(
          getTileUrl(
            Coords(x, y)..z = zoomLvl,
            options,
          ),
        );*/
        /*outlineTileNums[zoomLvl]!.add(
          [x, y],
        );*/
        /*final bytes = (await http.get(
          Uri.parse(
            getTileUrl(
              Coords(cord.x.toDouble(), cord.y.toDouble())
                ..z = cord.z.toDouble(),
              options,
            ),
          ),
        ))
            .bodyBytes;
        await TileStorageCachingManager.saveTile(bytes, cord);*/
      }

      for (int x in outlineTileNums[zoomLvl]!.keys) {
        for (int y = outlineTileNums[zoomLvl]![x]![0];
            y <= outlineTileNums[zoomLvl]![x]![1];
            y++) {
          final bytes = (await client.get(
            Uri.parse(
              getTileUrl(
                Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble(),
                options,
              ),
            ),
          ))
              .bodyBytes;
          await TileStorageCachingManager.saveTile(bytes,
              Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble());
        }
      }

      //outlineTileNums[zoomLvl].toString().printWrapped();

      /*print(outlineTileNums[zoomLvl]!);

      for (List<int> xy in outlineTileNums[zoomLvl]!) {
        int minused = 0;
        bool next = false;
        final http.Client client = http.Client();
        while (!next) {
          final bytes = (await client.get(
            Uri.parse(
              getTileUrl(
                Coords(xy[0].toDouble(), (xy[1] + minused).toDouble())
                  ..z = zoomLvl.toDouble(),
                options,
              ),
            ),
          ))
              .bodyBytes;
          await TileStorageCachingManager.saveTile(
              bytes,
              Coords(xy[0].toDouble(), (xy[1] - minused).toDouble())
                ..z = zoomLvl.toDouble());
          tmpCount++;
          print(tmpCount.toString() + [xy[0], xy[1] + minused].toString());
          //! CHECK NOT WORKING
          //! SEE 'xy[1] + minused'
          if (!outlineTileNums[zoomLvl]!.contains([xy[0], xy[1] + minused])) {
            print('yes');
            next = !next;
          }
          minused++;
        }
      }*/
    }

    //outlineTileNums.toString().printWrapped();

    /*for (var i = 0; i < tilesRange.length; i++) {
    try {
      final cord = tilesRange[i];
      final cordDouble = Coords(cord.x.toDouble(), cord.y.toDouble());
      cordDouble.z = cord.z.toDouble();
      final url = getTileUrl(cordDouble, options);
      final bytes = (await http.get(Uri.parse(url))).bodyBytes;
      await TileStorageCachingManager.saveTile(bytes, cord);
    } catch (e) {
      errorsCount++;
      if (errorHandler != null) errorHandler(e);
    }
    yield Tuple3(i + 1, errorsCount, tilesRange.length);
  }*/
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
    for (var i = 0; i < tilesRange.length; i++) {
      try {
        final cord = tilesRange[i];
        final cordDouble = Coords(cord.x.toDouble(), cord.y.toDouble());
        cordDouble.z = cord.z.toDouble();
        final url = getTileUrl(cordDouble, options);
        final bytes = (await http.get(Uri.parse(url))).bodyBytes;
        await TileStorageCachingManager.saveTile(bytes, cord);
      } catch (e) {
        errorsCount++;
        if (errorHandler != null) errorHandler(e);
      }
      yield Tuple3(i + 1, errorsCount, tilesRange.length);
    }
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
