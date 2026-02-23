import 'package:drift/drift.dart';

import 'store.dart';

/// Drift table tracking in-progress download recovery sessions
class DriftRecovery extends Table {
  /// Unique ID for the recovery session
  late final id = integer()();

  /// The name of the store being downloaded when the failure occurred
  late final store = text().references(DriftStore, #name)();

  /// The time the recovery session was created
  late final creationTime = dateTime().withDefault(currentDateAndTime)();

  /// Minimum zoom level of the download
  late final minZoom = integer()();

  /// Maximum zoom level of the download
  late final maxZoom = integer()();

  /// The tile index the download started from
  late final startTile = integer()();

  /// The tile index the download ended at
  late final endTile = integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
