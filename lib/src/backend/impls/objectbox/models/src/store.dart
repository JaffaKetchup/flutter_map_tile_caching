// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:objectbox/objectbox.dart';

import 'tile.dart';

/// Cache for store-level statistics & storage for metadata, referenced by
/// unique name, in ObjectBox
@Entity()
class ObjectBoxStore {
  /// Create a cache for store-level statistics & storage for metadata,
  /// referenced by unique name, in ObjectBox
  ObjectBoxStore({
    required this.name,
    required this.length,
    required this.size,
    required this.hits,
    required this.misses,
    required this.metadataJson,
  });

  /// ObjectBox ID
  @Id()
  int id = 0;

  /// Human-readable name of the store
  @Index()
  @Unique()
  String name;

  /// Relation to all tiles that belong to this store
  @Index()
  @Backlink('stores')
  final tiles = ToMany<ObjectBoxTile>();

  /// Number of tiles
  int length;

  /// Size (in bytes) of all tiles
  int size;

  /// Number of cache hits (successful retrievals) from this store only
  int hits;

  /// Number of cache misses (unsuccessful retrievals) from this store only
  int misses;

  /// Storage for metadata in JSON format
  ///
  /// Only supports string-string key-value pairs.
  String metadataJson;
}
