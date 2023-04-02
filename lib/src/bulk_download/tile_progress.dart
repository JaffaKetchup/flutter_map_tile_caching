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

  final bool wasCancelOperation;
  final List<int>? bulkTileWriterResponse;

  TileProgress({
    required this.failedUrl,
    required this.tileImage,
    required this.wasSeaTile,
    required this.wasExistingTile,
    required this.wasCancelOperation,
    required this.bulkTileWriterResponse,
  }) : sizeBytes = tileImage?.lengthInBytes ?? 0;

  @override
  String toString() =>
      'Tile Progress Report (${failedUrl != null ? 'Failed' : 'Successful'}):\n - `failedUrl`: $failedUrl\n - Has `tileImage`: ${tileImage != null}\n - `wasSeaTile`: $wasSeaTile\n - `wasExistingTile`: $wasExistingTile\n - `sizeBytes`: $sizeBytes\n - `wasCancelOperation`: $wasCancelOperation\n - `bulkTileWriterResponse`: $bulkTileWriterResponse';
}
