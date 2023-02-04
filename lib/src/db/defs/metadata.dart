// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../tools.dart';

part 'metadata.g.dart';

@internal
@Collection(accessor: 'metadata')
class DbMetadata {
  Id get id => DatabaseTools.hash(name);

  final String name;
  final String data;

  DbMetadata({
    required this.name,
    required this.data,
  });
}
