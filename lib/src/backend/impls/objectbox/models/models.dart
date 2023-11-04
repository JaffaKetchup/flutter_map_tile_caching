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

  ObjectBoxStore({required this.name});
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
