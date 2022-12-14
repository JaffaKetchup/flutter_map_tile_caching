// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../../../flutter_map_tile_caching.dart';

part 'recovery.g.dart';

@internal
@Collection(accessor: 'recovery')
class DbRecoverableRegion {
  final Id id;
  final String storeName;
  final DateTime time;
  @enumerated
  final RegionType type;

  final int minZoom;
  final int maxZoom;

  final int start;
  final int? end;

  final int parallelThreads;
  final bool preventRedownload;
  final bool seaTileRemoval;

  final double? nwLat;
  final double? nwLng;
  final double? seLat;
  final double? seLng;

  final double? centerLat;
  final double? centerLng;
  final double? circleRadius;

  final List<double>? linePointsLat;
  final List<double>? linePointsLng;
  final double? lineRadius;

  DbRecoverableRegion({
    required this.id,
    required this.storeName,
    required this.time,
    required this.type,
    required this.minZoom,
    required this.maxZoom,
    required this.start,
    this.end,
    required this.parallelThreads,
    required this.preventRedownload,
    required this.seaTileRemoval,
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
