// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

part 'recovery.g.dart';

@internal
enum RegionType { rectangle, circle, line, customPolygon }

@internal
@Collection(accessor: 'recovery')
class DbRecoverableRegion {
  final Id id;
  final String storeName;
  final DateTime time;
  @enumerated
  final RegionType type;

  final byte minZoom;
  final byte maxZoom;

  final short start;
  final short? end;

  final float? nwLat;
  final float? nwLng;
  final float? seLat;
  final float? seLng;

  final float? centerLat;
  final float? centerLng;
  final float? circleRadius;

  final List<float>? linePointsLat;
  final List<float>? linePointsLng;
  final float? lineRadius;

  DbRecoverableRegion({
    required this.id,
    required this.storeName,
    required this.time,
    required this.type,
    required this.minZoom,
    required this.maxZoom,
    required this.start,
    this.end,
    this.nwLat,
    this.nwLng,
    this.seLat,
    this.seLng,
    this.centerLat,
    this.centerLng,
    this.circleRadius,
    this.linePointsLat,
    this.linePointsLng,
    this.lineRadius,
  });
}
