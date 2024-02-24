// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

import '../../../../interfaces/models.dart';
import 'store.dart';

@Entity()
base class ObjectBoxTile extends BackendTile {
  ObjectBoxTile({
    required this.url,
    required this.lastModified,
    required this.bytes,
  });

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
}
