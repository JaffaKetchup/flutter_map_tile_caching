import 'package:drift/drift.dart';

class DriftRoot extends Table {
  late final Column<int> id =
      integer().check(id.equals(0)).withDefault(const Constant(0))();

  late final length = integer().withDefault(const Constant(0))();
  late final size = integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
