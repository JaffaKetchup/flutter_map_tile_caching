import 'package:drift/drift.dart';

import 'recovery.dart';

class DriftRecoveryRegion extends Table {
  late final id = integer().autoIncrement()();
  late final recovery = integer().references(DriftRecovery, #id)();

  late final Column<int> typeId =
      integer().check(typeId.isBetweenValues(0, 3))();

  late final rectNwLat = real().nullable()();
  late final rectNwLng = real().nullable()();
  late final rectSeLat = real().nullable()();
  late final rectSeLng = real().nullable()();

  late final circleCenterLat = real().nullable()();
  late final circleCenterLng = real().nullable()();
  late final circleRadius = real().nullable()();

  late final Column<String> lineLats = text().nullable()();
  late final Column<String> lineLngs = text().nullable()();
  late final lineRadius = real().nullable()();

  late final Column<String> customPolygonLats = text().nullable()();
  late final Column<String> customPolygonLngs = text().nullable()();

  @override
  bool get isStrict => true;
}
