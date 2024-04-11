import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class EmptyTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) =>
      MemoryImage(TileProvider.transparentImage);
}
