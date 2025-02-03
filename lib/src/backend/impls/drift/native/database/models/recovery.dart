import 'package:drift/drift.dart';

import 'store.dart';

class DriftRecovery extends Table {
  late final id = integer()();
  late final store = text().references(DriftStore, #name)();

  late final creationTime = dateTime().withDefault(currentDateAndTime)();

  late final minZoom = integer()();
  late final maxZoom = integer()();
  late final startTile = integer()();
  late final endTile = integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
