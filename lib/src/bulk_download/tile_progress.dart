// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

class TileProgress {
  final String? failedUrl;
  final bool wasSeaTile;
  final bool wasExistingTile;
  final Uint8List? tileImage;
  final int sizeBytes;

  TileProgress({
    required this.failedUrl,
    required this.wasSeaTile,
    required this.wasExistingTile,
    required this.tileImage,
  }) : sizeBytes = tileImage?.lengthInBytes ?? 0;

  @override
  String toString() =>
      'TileProgress(failedUrl: $failedUrl, wasSeaTile: $wasSeaTile, wasExistingTile: $wasExistingTile, tileImage: $tileImage, sizeBytes: $sizeBytes)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TileProgress &&
        other.failedUrl == failedUrl &&
        other.wasSeaTile == wasSeaTile &&
        other.wasExistingTile == wasExistingTile &&
        other.tileImage == tileImage &&
        other.sizeBytes == sizeBytes;
  }

  @override
  int get hashCode =>
      failedUrl.hashCode ^
      wasSeaTile.hashCode ^
      wasExistingTile.hashCode ^
      tileImage.hashCode ^
      sizeBytes.hashCode;
}
