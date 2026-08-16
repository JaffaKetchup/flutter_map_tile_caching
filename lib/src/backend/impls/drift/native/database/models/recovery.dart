import 'package:drift/drift.dart';

import 'store.dart';

/// Drift table tracking in-progress download recovery sessions
class DriftRecovery extends Table {
  /// Unique ID for the recovery session
  IntColumn get id => integer()();

  /// The name of the store being downloaded when the failure occurred
  TextColumn get store => text().references(DriftStore, #name)();

  /// The time the recovery session was created
  DateTimeColumn get creationTime => dateTime().withDefault(currentDateAndTime)();

  /// Minimum zoom level of the download
  IntColumn get minZoom => integer()();

  /// Maximum zoom level of the download
  IntColumn get maxZoom => integer()();

  /// The tile index the download started from
  IntColumn get startTile => integer()();

  /// The tile index the download ended at
  IntColumn get endTile => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
