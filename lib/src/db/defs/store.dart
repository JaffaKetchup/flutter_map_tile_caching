import 'package:isar/isar.dart';

import '../misc/hash.dart';
part 'store.g.dart';

@Collection(accessor: 'stores')
class Store {
  final Id id;

  final String name;

  int hits = 0;
  int misses = 0;

  Store({
    required this.name,
  }) : id = databaseHash(name);
}
