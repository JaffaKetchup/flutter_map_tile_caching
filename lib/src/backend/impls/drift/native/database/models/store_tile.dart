import 'package:drift/drift.dart';

// ignore: unused_import -- required for drift_dev FK resolution
import 'store.dart';
// ignore: unused_import -- required for drift_dev FK resolution
import 'tile.dart';

@TableIndex(name: 'idx_store_tile_tile', columns: {#tile})

/// Drift junction table linking tiles to their containing stores
class DriftStoreTile extends Table {
  /// Foreign key to [DriftStore] with cascade on update/delete
  late final store = text().customConstraint(
    'REFERENCES drift_store(name) ON UPDATE CASCADE ON DELETE CASCADE NOT NULL',
  )();

  /// Foreign key to [DriftTile] with cascade on delete
  late final tile = text().customConstraint(
    'REFERENCES drift_tile(uid) ON DELETE CASCADE NOT NULL',
  )();

  @override
  Set<Column<Object>> get primaryKey => {store, tile};

  @override
  bool get isStrict => true;

  @override
  bool get withoutRowId => true;
}
