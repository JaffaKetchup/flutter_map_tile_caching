// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../flutter_map_tile_caching.dart';

@Entity()
base class ObjectBoxRecovery {
  ObjectBoxRecovery({
    required this.refId,
    required this.storeName,
    required this.creationTime,
    required this.typeId,
    required this.minZoom,
    required this.maxZoom,
    required this.startTile,
    required this.endTile,
    required this.rectNwLat,
    required this.rectNwLng,
    required this.rectSeLat,
    required this.rectSeLng,
    required this.circleCenterLat,
    required this.circleCenterLng,
    required this.circleRadius,
    required this.lineLats,
    required this.lineLngs,
    required this.lineRadius,
    required this.customPolygonLats,
    required this.customPolygonLngs,
  });

  ObjectBoxRecovery.fromRegion({
    required this.refId,
    required this.storeName,
    required DownloadableRegion region,
  })  : creationTime = DateTime.timestamp(),
        typeId = region.when(
          rectangle: (_) => 0,
          circle: (_) => 1,
          line: (_) => 2,
          customPolygon: (_) => 3,
        ),
        minZoom = region.minZoom,
        maxZoom = region.maxZoom,
        startTile = region.start,
        endTile = region.end,
        rectNwLat = region.originalRegion is RectangleRegion
            ? (region.originalRegion as RectangleRegion)
                .bounds
                .northWest
                .latitude
            : null,
        rectNwLng = region.originalRegion is RectangleRegion
            ? (region.originalRegion as RectangleRegion)
                .bounds
                .northWest
                .longitude
            : null,
        rectSeLat = region.originalRegion is RectangleRegion
            ? (region.originalRegion as RectangleRegion)
                .bounds
                .southEast
                .latitude
            : null,
        rectSeLng = region.originalRegion is RectangleRegion
            ? (region.originalRegion as RectangleRegion)
                .bounds
                .southEast
                .longitude
            : null,
        circleCenterLat = region.originalRegion is CircleRegion
            ? (region.originalRegion as CircleRegion).center.latitude
            : null,
        circleCenterLng = region.originalRegion is CircleRegion
            ? (region.originalRegion as CircleRegion).center.longitude
            : null,
        circleRadius = region.originalRegion is CircleRegion
            ? (region.originalRegion as CircleRegion).radius
            : null,
        lineLats = region.originalRegion is LineRegion
            ? (region.originalRegion as LineRegion)
                .line
                .map((c) => c.latitude)
                .toList()
            : null,
        lineLngs = region.originalRegion is LineRegion
            ? (region.originalRegion as LineRegion)
                .line
                .map((c) => c.longitude)
                .toList()
            : null,
        lineRadius = region.originalRegion is LineRegion
            ? (region.originalRegion as LineRegion).radius
            : null,
        customPolygonLats = region.originalRegion is CustomPolygonRegion
            ? (region.originalRegion as CustomPolygonRegion)
                .outline
                .map((c) => c.latitude)
                .toList()
            : null,
        customPolygonLngs = region.originalRegion is CustomPolygonRegion
            ? (region.originalRegion as CustomPolygonRegion)
                .outline
                .map((c) => c.longitude)
                .toList()
            : null;

  @Id()
  @internal
  int id = 0;

  @Index()
  @Unique()
  int refId;

  String storeName;
  @Property(type: PropertyType.date)
  DateTime creationTime;

  int minZoom;
  int maxZoom;
  int startTile;
  int? endTile;

  int typeId; // 0 - rect, 1 - circle, 2 - line, 3 - custom polygon

  double? rectNwLat;
  double? rectNwLng;
  double? rectSeLat;
  double? rectSeLng;

  double? circleCenterLat;
  double? circleCenterLng;
  double? circleRadius;

  List<double>? lineLats;
  List<double>? lineLngs;
  double? lineRadius;

  List<double>? customPolygonLats;
  List<double>? customPolygonLngs;

  RecoveredRegion toRegion() => RecoveredRegion(
        id: refId,
        storeName: storeName,
        time: creationTime,
        bounds: typeId == 0
            ? LatLngBounds(
                LatLng(rectNwLat!, rectNwLng!),
                LatLng(rectSeLat!, rectSeLng!),
              )
            : null,
        center: typeId == 1 ? LatLng(circleCenterLat!, circleCenterLng!) : null,
        line: typeId == 2 || typeId == 3
            ? List.generate(
                lineLats!.length,
                (i) => LatLng(lineLats![i], lineLngs![i]),
              )
            : null,
        radius: typeId == 1
            ? circleRadius!
            : typeId == 2
                ? lineRadius!
                : null,
        minZoom: minZoom,
        maxZoom: maxZoom,
        start: startTile,
        end: endTile,
      );
}
