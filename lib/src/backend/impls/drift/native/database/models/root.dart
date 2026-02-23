import 'package:drift/drift.dart';

/// Drift table for the FMTC root statistics singleton row
class DriftRoot extends Table {
  /// Singleton row ID (always 0)
  late final Column<int> id =
      integer().check(id.equals(0)).withDefault(const Constant(0))();

  /// Total number of tiles across all stores
  late final length = integer().withDefault(const Constant(0))();

  /// Total size in bytes across all stores
  late final size = integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
