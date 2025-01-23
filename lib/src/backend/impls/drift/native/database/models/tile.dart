import 'package:drift/drift.dart';

@TableIndex(name: 'last_modified', columns: {#lastModified})
class DriftTile extends Table {
  late final uid = text()();
  late final bytes = blob()();
  late final lastModified = dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {uid};

  @override
  bool get isStrict => true;
}
