// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:meta/meta.dart';

@internal
class TileProgress {
  final String? failedUrl;
  final Uint8List? tileImage;

  final bool wasSeaTile;
  final bool wasExistingTile;
  final int sizeBytes;

  final List<int>? bulkTileWriterResponse;

  TileProgress({
    required this.failedUrl,
    required this.tileImage,
    required this.wasSeaTile,
    required this.wasExistingTile,
    required this.bulkTileWriterResponse,
  }) : sizeBytes = tileImage?.lengthInBytes ?? 0;
}
