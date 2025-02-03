import 'package:drift/drift.dart';

import 'database.drift.dart';
import 'models/recovery.dart';
import 'models/recovery_region.dart';
import 'models/root.dart';
import 'models/store.dart';
import 'models/store_tile.dart';
import 'models/tile.dart';

@DriftDatabase(
  tables: [
    DriftTile,
    DriftStore,
    DriftStoreTile,
    DriftRoot,
    DriftRecovery,
    DriftRecoveryRegion,
  ],
)
class DriftFMTCDatabase extends $DriftFMTCDatabase {
  DriftFMTCDatabase(QueryExecutor connection) : super(connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
