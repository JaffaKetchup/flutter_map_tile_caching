// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/tile.drift.dart'
    as i1;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store.drift.dart'
    as i2;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store_tile.drift.dart'
    as i3;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/root.drift.dart'
    as i4;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery.drift.dart'
    as i5;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery_region.drift.dart'
    as i6;

abstract class $DriftFMTCDatabase extends i0.GeneratedDatabase {
  $DriftFMTCDatabase(i0.QueryExecutor e) : super(e);
  $DriftFMTCDatabaseManager get managers => $DriftFMTCDatabaseManager(this);
  late final i1.$DriftTileTable driftTile = i1.$DriftTileTable(this);
  late final i2.$DriftStoreTable driftStore = i2.$DriftStoreTable(this);
  late final i3.$DriftStoreTileTable driftStoreTile =
      i3.$DriftStoreTileTable(this);
  late final i4.$DriftRootTable driftRoot = i4.$DriftRootTable(this);
  late final i5.$DriftRecoveryTable driftRecovery =
      i5.$DriftRecoveryTable(this);
  late final i6.$DriftRecoveryRegionTable driftRecoveryRegion =
      i6.$DriftRecoveryRegionTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
        driftTile,
        driftStore,
        driftStoreTile,
        driftRoot,
        driftRecovery,
        driftRecoveryRegion,
        i1.lastModified
      ];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $DriftFMTCDatabaseManager {
  final $DriftFMTCDatabase _db;
  $DriftFMTCDatabaseManager(this._db);
  i1.$$DriftTileTableTableManager get driftTile =>
      i1.$$DriftTileTableTableManager(_db, _db.driftTile);
  i2.$$DriftStoreTableTableManager get driftStore =>
      i2.$$DriftStoreTableTableManager(_db, _db.driftStore);
  i3.$$DriftStoreTileTableTableManager get driftStoreTile =>
      i3.$$DriftStoreTileTableTableManager(_db, _db.driftStoreTile);
  i4.$$DriftRootTableTableManager get driftRoot =>
      i4.$$DriftRootTableTableManager(_db, _db.driftRoot);
  i5.$$DriftRecoveryTableTableManager get driftRecovery =>
      i5.$$DriftRecoveryTableTableManager(_db, _db.driftRecovery);
  i6.$$DriftRecoveryRegionTableTableManager get driftRecoveryRegion =>
      i6.$$DriftRecoveryRegionTableTableManager(_db, _db.driftRecoveryRegion);
}
