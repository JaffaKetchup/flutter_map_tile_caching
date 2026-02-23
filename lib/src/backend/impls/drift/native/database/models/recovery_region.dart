import 'package:drift/drift.dart';

import 'recovery.dart';

/// Drift table storing the serialized region geometry for each recovery session
class DriftRecoveryRegion extends Table {
  /// Auto-incremented primary key
  late final id = integer().autoIncrement()();

  /// The recovery session this region belongs to
  late final recovery = integer().references(DriftRecovery, #id)();

  /// For MultiRegion sub-regions, references the parent DriftRecoveryRegion.id
  late final parentRegionId = integer().nullable()();

  /// Integer discriminator identifying the region type (0–4)
  late final Column<int> typeId =
      integer().check(typeId.isBetweenValues(0, 4))();

  /// North-west latitude of a rectangular region
  late final rectNwLat = real().nullable()();

  /// North-west longitude of a rectangular region
  late final rectNwLng = real().nullable()();

  /// South-east latitude of a rectangular region
  late final rectSeLat = real().nullable()();

  /// South-east longitude of a rectangular region
  late final rectSeLng = real().nullable()();

  /// Center latitude of a circular region
  late final circleCenterLat = real().nullable()();

  /// Center longitude of a circular region
  late final circleCenterLng = real().nullable()();

  /// Radius in meters of a circular region
  late final circleRadius = real().nullable()();

  /// JSON-encoded list of latitudes for a line region
  late final Column<String> lineLats = text().nullable()();

  /// JSON-encoded list of longitudes for a line region
  late final Column<String> lineLngs = text().nullable()();

  /// Buffer radius in meters for a line region
  late final lineRadius = real().nullable()();

  /// JSON-encoded list of latitudes for a custom polygon region
  late final Column<String> customPolygonLats = text().nullable()();

  /// JSON-encoded list of longitudes for a custom polygon region
  late final Column<String> customPolygonLngs = text().nullable()();

  @override
  bool get isStrict => true;
}
