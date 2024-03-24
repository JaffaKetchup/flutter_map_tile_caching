// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:objectbox/objectbox.dart';

/// Cache for root-level statistics in ObjectBox
@Entity()
class ObjectBoxRoot {
  /// Create a new cache for root-level statistics in ObjectBox
  ObjectBoxRoot({
    required this.length,
    required this.size,
  });

  /// ObjectBox ID
  @Id()
  int id = 0;

  /// Total number of tiles
  int length;

  /// Total size (in bytes) of all tiles
  int size;
}
