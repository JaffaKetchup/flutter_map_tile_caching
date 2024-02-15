// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:objectbox/objectbox.dart';

import 'tile.dart';

@Entity()
class ObjectBoxStore {
  @Id()
  int id = 0;

  @Index()
  @Unique()
  String name;

  @Index()
  @Backlink('stores')
  final tiles = ToMany<ObjectBoxTile>();

  int length;
  double size;
  int hits;
  int misses;
  String metadataJson;

  ObjectBoxStore({
    required this.name,
    required this.length,
    required this.size,
    required this.hits,
    required this.misses,
  }) : metadataJson = '';
}
