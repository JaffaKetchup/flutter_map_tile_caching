// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../flutter_map_tile_caching.dart';

/// Represents a [RecoveredRegion] in ObjectBox
@Entity()
base class ObjectBoxRecovery {
  /// Create a raw representation of a [RecoveredRegion] in ObjectBox
  ///
  /// Prefer using [ObjectBoxRecovery.fromRegion].
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

  /// Create a raw representation of a [RecoveredRegion] in ObjectBox from a
  /// [DownloadableRegion]
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
                .toList(growable: false)
            : null,
        lineLngs = region.originalRegion is LineRegion
            ? (region.originalRegion as LineRegion)
                .line
                .map((c) => c.longitude)
                .toList(growable: false)
            : null,
        lineRadius = region.originalRegion is LineRegion
            ? (region.originalRegion as LineRegion).radius
            : null,
        customPolygonLats = region.originalRegion is CustomPolygonRegion
            ? (region.originalRegion as CustomPolygonRegion)
                .outline
                .map((c) => c.latitude)
                .toList(growable: false)
            : null,
        customPolygonLngs = region.originalRegion is CustomPolygonRegion
            ? (region.originalRegion as CustomPolygonRegion)
                .outline
                .map((c) => c.longitude)
                .toList(growable: false)
            : null;

  /// ObjectBox ID
  ///
  /// Not to be confused with [refId].
  @Id()
  @internal
  int id = 0;

  /// Corresponds to [RecoveredRegion.id]
  @Index()
  @Unique()
  int refId;

  /// Corresponds to [RecoveredRegion.storeName]
  String storeName;

  /// The timestamp of when this object was created/stored
  @Property(type: PropertyType.date)
  DateTime creationTime;

  /// Corresponds to [RecoveredRegion.minZoom] & [DownloadableRegion.minZoom]
  int minZoom;

  /// Corresponds to [RecoveredRegion.maxZoom] & [DownloadableRegion.maxZoom]
  int maxZoom;

  /// Corresponds to [RecoveredRegion.start] & [DownloadableRegion.start]
  int startTile;

  /// Corresponds to [RecoveredRegion.end] & [DownloadableRegion.end]
  int? endTile;

  /// Corresponds to the generic type of [DownloadableRegion]
  ///
  /// Values must be as follows:
  /// * 0: rect
  /// * 1: circle
  /// * 2: line
  /// * 3: custom polygon
  int typeId;

  /// Corresponds to [RecoveredRegion.bounds] ([RectangleRegion.bounds])
  double? rectNwLat;

  /// Corresponds to [RecoveredRegion.bounds] ([RectangleRegion.bounds])
  double? rectNwLng;

  /// Corresponds to [RecoveredRegion.bounds] ([RectangleRegion.bounds])
  double? rectSeLat;

  /// Corresponds to [RecoveredRegion.bounds] ([RectangleRegion.bounds])
  double? rectSeLng;

  /// Corresponds to [RecoveredRegion.center] ([CircleRegion.center])
  double? circleCenterLat;

  /// Corresponds to [RecoveredRegion.center] ([CircleRegion.center])
  double? circleCenterLng;

  /// Corresponds to [RecoveredRegion.radius] ([CircleRegion.radius])
  double? circleRadius;

  /// Corresponds to [RecoveredRegion.line] ([LineRegion.line])
  List<double>? lineLats;

  /// Corresponds to [RecoveredRegion.line] ([LineRegion.line])
  List<double>? lineLngs;

  /// Corresponds to [RecoveredRegion.radius] ([LineRegion.radius])
  double? lineRadius;

  /// Corresponds to [RecoveredRegion.line] ([CustomPolygonRegion.outline])
  List<double>? customPolygonLats;

  /// Corresponds to [RecoveredRegion.line] ([CustomPolygonRegion.outline])
  List<double>? customPolygonLngs;

  /// Convert this object into a [RecoveredRegion]
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
        line: typeId == 2
            ? List.generate(
                lineLats!.length,
                (i) => LatLng(lineLats![i], lineLngs![i]),
              )
            : typeId == 3
                ? List.generate(
                    customPolygonLats!.length,
                    (i) => LatLng(customPolygonLats![i], customPolygonLngs![i]),
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
