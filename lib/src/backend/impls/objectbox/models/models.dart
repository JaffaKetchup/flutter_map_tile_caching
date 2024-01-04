// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

import '../../../interfaces/models.dart';

@Entity()
base class ObjectBoxStore extends BackendStore {
  @Id()
  int id = 0;

  @override
  @Index()
  @Unique()
  String name;

  @Index()
  @Backlink()
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

@Entity()
base class ObjectBoxTile extends BackendTile {
  @Id()
  int id = 0;

  @override
  @Index()
  @Unique(onConflict: ConflictStrategy.replace)
  String url;

  @override
  @Index()
  @Property(type: PropertyType.date)
  DateTime lastModified;

  @override
  Uint8List bytes;

  @Index()
  final stores = ToMany<ObjectBoxStore>();

  ObjectBoxTile({
    required this.url,
    required this.lastModified,
    required this.bytes,
  });
}
