import 'package:drift/drift.dart';

/// Drift table for FMTC tile stores
class DriftStore extends Table {
  /// The unique name of the store
  late final name = text()();

  /// Maximum number of tiles allowed in the store (null = unlimited)
  late final maxLength = integer().nullable()();

  /// Current number of tiles in the store
  late final length = integer().withDefault(const Constant(0))();

  /// Total size of all tiles in bytes
  late final size = integer().withDefault(const Constant(0))();

  /// Number of cache hits recorded for this store
  late final hits = integer().withDefault(const Constant(0))();

  /// Number of cache misses recorded for this store
  late final misses = integer().withDefault(const Constant(0))();

  /// JSON-encoded key-value metadata for this store
  late final metadataJson = text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {name};

  @override
  bool get isStrict => true;

  @override
  bool get withoutRowId => true;
}
