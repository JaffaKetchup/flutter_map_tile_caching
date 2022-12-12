import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../tools.dart';

part 'store.g.dart';

@internal
@Collection(accessor: 'stores')
class DbStore {
  Id get id => DatabaseTools.hash(name);

  final String name;

  int hits = 0;
  int misses = 0;

  DbStore({required this.name});
}
