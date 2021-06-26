import 'package:flutter_map/plugin_api.dart' show TileLayerOptions;
import 'package:latlong2/latlong.dart';

enum RegionType {
  square,
  circle,
  line,
  customPolygon,
}

class DownloadableRegion {
  final List<LatLng> points;
  final int minZoom;
  final int maxZoom;
  final RegionType type;
  final TileLayerOptions options;

  final Function(dynamic)? errorHandler;

  DownloadableRegion(
    this.points,
    this.minZoom,
    this.maxZoom,
    this.options,
    this.type, [
    this.errorHandler,
  ]);
}
