// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../tools.dart';

part 'tile.g.dart';

@internal
@Collection(accessor: 'tiles')
class DbTile {
  Id get id => DatabaseTools.hash(url);

  final String url;
  final List<byte> bytes;

  @Index()
  final DateTime lastModified;

  DbTile({
    required this.url,
    required this.bytes,
  }) : lastModified = DateTime.now();
}
