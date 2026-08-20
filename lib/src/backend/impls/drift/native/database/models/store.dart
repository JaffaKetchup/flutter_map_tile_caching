import 'package:drift/drift.dart';

/// Drift table for FMTC tile stores
class DriftStore extends Table {
  /// The unique name of the store
  TextColumn get name => text()();

  /// Maximum number of tiles allowed in the store (null = unlimited)
  IntColumn get maxLength => integer().nullable()();

  /// Current number of tiles in the store
  IntColumn get length => integer().withDefault(const Constant(0))();

  /// Total size of all tiles in bytes
  IntColumn get size => integer().withDefault(const Constant(0))();

  /// Number of cache hits recorded for this store
  IntColumn get hits => integer().withDefault(const Constant(0))();

  /// Number of cache misses recorded for this store
  IntColumn get misses => integer().withDefault(const Constant(0))();

  /// JSON-encoded key-value metadata for this store
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {name};

  @override
  bool get isStrict => true;

  @override
  bool get withoutRowId => true;
}
