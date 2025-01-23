import 'package:drift/drift.dart';

class DriftStore extends Table {
  late final name = text()();
  late final maxLength = integer().nullable()();
  late final length = integer().withDefault(const Constant(0))();
  late final size = integer().withDefault(const Constant(0))();
  late final hits = integer().withDefault(const Constant(0))();
  late final misses = integer().withDefault(const Constant(0))();
  late final metadataJson = text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {name};

  @override
  bool get isStrict => true;

  @override
  bool get withoutRowId => true;
}
