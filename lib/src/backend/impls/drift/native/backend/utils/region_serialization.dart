// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:drift/drift.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../../flutter_map_tile_caching.dart';
import '../../database/models/recovery_region.drift.dart';

/// Convert a [BaseRegion] to a [DriftRecoveryRegionCompanion] for insertion
DriftRecoveryRegionCompanion regionToCompanion({
  required BaseRegion region,
  required int recoveryId,
  int? parentRegionId,
}) {
  final typeId = switch (region) {
    RectangleRegion() => 0,
    CircleRegion() => 1,
    LineRegion() => 2,
    CustomPolygonRegion() => 3,
    MultiRegion() => 4,
  };

  return DriftRecoveryRegionCompanion.insert(
    recovery: recoveryId,
    parentRegionId: Value(parentRegionId),
    typeId: typeId,
    rectNwLat: Value(
      region is RectangleRegion ? region.bounds.northWest.latitude : null,
    ),
    rectNwLng: Value(
      region is RectangleRegion ? region.bounds.northWest.longitude : null,
    ),
    rectSeLat: Value(
      region is RectangleRegion ? region.bounds.southEast.latitude : null,
    ),
    rectSeLng: Value(
      region is RectangleRegion ? region.bounds.southEast.longitude : null,
    ),
    circleCenterLat: Value(
      region is CircleRegion ? region.center.latitude : null,
    ),
    circleCenterLng: Value(
      region is CircleRegion ? region.center.longitude : null,
    ),
    circleRadius: Value(region is CircleRegion ? region.radius : null),
    lineLats: Value(
      region is LineRegion
          ? region.line.map((c) => c.latitude).join(',')
          : null,
    ),
    lineLngs: Value(
      region is LineRegion
          ? region.line.map((c) => c.longitude).join(',')
          : null,
    ),
    lineRadius: Value(region is LineRegion ? region.radius : null),
    customPolygonLats: Value(
      region is CustomPolygonRegion
          ? region.outline.map((c) => c.latitude).join(',')
          : null,
    ),
    customPolygonLngs: Value(
      region is CustomPolygonRegion
          ? region.outline.map((c) => c.longitude).join(',')
          : null,
    ),
  );
}

/// Convert a [DriftRecoveryRegionData] and its children to a [BaseRegion]
BaseRegion dataToRegion(
  DriftRecoveryRegionData data,
  List<DriftRecoveryRegionData> allRegionData,
) =>
    switch (data.typeId) {
      0 => RectangleRegion(
          LatLngBounds(
            LatLng(data.rectNwLat!, data.rectNwLng!),
            LatLng(data.rectSeLat!, data.rectSeLng!),
          ),
        ),
      1 => CircleRegion(
          LatLng(data.circleCenterLat!, data.circleCenterLng!),
          data.circleRadius!,
        ),
      2 => LineRegion(
          _parseCoordList(data.lineLats!, data.lineLngs!),
          data.lineRadius!,
        ),
      3 => CustomPolygonRegion(
          _parseCoordList(data.customPolygonLats!, data.customPolygonLngs!),
        ),
      4 => MultiRegion(
          allRegionData
              .where((child) => child.parentRegionId == data.id)
              .map((child) => dataToRegion(child, allRegionData))
              .toList(growable: false),
        ),
      _ => throw UnimplementedError('Unknown region typeId: ${data.typeId}'),
    };

List<LatLng> _parseCoordList(String lats, String lngs) {
  final latList = lats.split(',').map(double.parse).toList();
  final lngList = lngs.split(',').map(double.parse).toList();
  return List.generate(
    latList.length,
    (i) => LatLng(latList[i], lngList[i]),
  );
}
