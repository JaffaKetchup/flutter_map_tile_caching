import 'dart:typed_data';

class TileProgress {
  final String? failedUrl;
  final bool wasSeaTile;
  final bool wasExistingTile;
  final Uint8List? tileImage;

  TileProgress({
    required this.failedUrl,
    required this.wasSeaTile,
    required this.wasExistingTile,
    required this.tileImage,
  });
}
