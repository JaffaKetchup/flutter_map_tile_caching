import 'package:drift/drift.dart';

@TableIndex(name: 'last_modified', columns: {#lastModified})

/// Drift table for cached map tiles
class DriftTile extends Table {
  /// The URL of the tile, used as a unique identifier
  late final uid = text()();

  /// The raw image bytes of the tile
  late final bytes = blob()();

  /// The time the tile was last written or updated
  late final lastModified = dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {uid};

  @override
  bool get isStrict => true;
}
