// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

import '../../../../interfaces/models.dart';
import 'store.dart';

/// ObjectBox-specific implementation of [BackendTile]
@Entity()
base class ObjectBoxTile extends BackendTile {
  /// Create an ObjectBox-specific implementation of [BackendTile]
  ObjectBoxTile({
    required this.url,
    required this.bytes,
    required this.lastModified,
  });

  /// ObjectBox ID
  @Id()
  int id = 0;

  @override
  @Index()
  @Unique(onConflict: ConflictStrategy.replace)
  String url;

  @override
  Uint8List bytes;

  @override
  @Index()
  @Property(type: PropertyType.date)
  DateTime lastModified;

  /// Relation to all stores that this tile belongs to
  @Index()
  final stores = ToMany<ObjectBoxStore>();
}
