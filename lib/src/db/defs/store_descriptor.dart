// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

part 'store_descriptor.g.dart';

@internal
@Collection(accessor: 'storeDescriptor')
class DbStoreDescriptor {
  final Id id = 0;
  final String name;

  int hits = 0;
  int misses = 0;

  DbStoreDescriptor({required this.name});
}
