import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'models/recovery.dart';
import 'models/recovery_region.dart';
import 'models/root.dart';
import 'models/store.dart';
import 'models/store_tile.dart';
import 'models/tile.dart';

// https://drift.simonbinder.eu/faq#my-generated-code-is-using-another-class-with-the-same-name
import 'database.drift.dart';

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

/// The main Drift database class for FMTC's native SQLite backend
class DriftFMTCDatabase extends $DriftFMTCDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  DriftFMTCDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  //
  // ignore: prefer_expression_function_bodies
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        // databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }
}
