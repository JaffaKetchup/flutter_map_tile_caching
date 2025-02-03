import 'package:drift/drift.dart';

import 'store.dart';
import 'tile.dart';

class DriftStoreTile extends Table {
  late final store = text().references(DriftStore, #name)();
  late final tile = text().references(DriftTile, #uid)();

  @override
  Set<Column<Object>> get primaryKey => {store, tile};

  @override
  bool get isStrict => true;

  @override
  bool get withoutRowId => true;
}
