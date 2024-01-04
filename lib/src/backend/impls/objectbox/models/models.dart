import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

import '../../../interfaces/models.dart';

@Entity()
base class ObjectBoxStore extends BackendStore<ToMany<ObjectBoxTile>> {
  @Id()
  int id = 0;

  @override
  @Index()
  @Unique()
  String name;

  int numberOfTiles;

  double numberOfBytes;

  @override
  int hits;

  @override
  int misses;

  @override
  @Index()
  @Backlink()
  final tiles = ToMany<ObjectBoxTile>();

  ObjectBoxStore({
    required this.name,
    required this.numberOfTiles,
    required this.numberOfBytes,
    required this.hits,
    required this.misses,
  });
}

@Entity()
base class ObjectBoxTile extends BackendTile<ToMany<ObjectBoxStore>> {
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

  @override
  @Index()
  final stores = ToMany<ObjectBoxStore>();

  ObjectBoxTile({
    required this.url,
    required this.lastModified,
    required this.bytes,
  });
}
