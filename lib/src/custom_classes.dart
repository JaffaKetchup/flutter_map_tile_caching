import 'package:flutter_map/plugin_api.dart'
    show LatLngBounds, TileLayerOptions;

class DownloadOptions {
  LatLngBounds bounds;
  int minZoom;
  int maxZoom;
  TileLayerOptions options;

  DownloadOptions({
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.options,
  });
}
