// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

part 'tile.g.dart';

/// Maximum number in one dimension at zoom level 32
///
/// Square to get the total number of tiles available at zoom level 32
const _maxTileNumber = 4294967296;

/// Representation of a map tile, containing its postition, image bytes, and
/// other important metadata
@internal
@Collection(accessor: 'tiles')
class DbTile {
  /// Generated automatically on creation by the formula: `z + y * m + x * m * m`,
  /// where `m` is the maximum number in one dimension at zoom level 32
  Id get id => z + y * _maxTileNumber + x * _maxTileNumber * _maxTileNumber;

  /// x position of tile
  final short x;

  /// y position of tile
  final short y;

  /// z position of tile
  final short z;

  /// Bytes of the actual image, to be painted later
  final List<byte> bytes;

  /// Shortcut for retrieving the length (size) of [bytes] in KiB
  final float length;

  /// Time at which this tile was stored, for processing by the 'Remove Oldest
  /// First' algorithm
  ///
  /// Generated automatically on creation
  @Index()
  final DateTime created;

  /// Create a map tile using its postition, image bytes, and other important
  /// metadata
  DbTile({
    required this.x,
    required this.y,
    required this.z,
    required this.bytes,
  })  : created = DateTime.now(),
        length = Uint8List.fromList(bytes).lengthInBytes / 1024;
}
