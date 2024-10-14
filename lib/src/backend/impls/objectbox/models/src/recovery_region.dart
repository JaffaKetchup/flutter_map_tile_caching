// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../flutter_map_tile_caching.dart';

/// Serialised [BaseRegion]
@Entity()
class ObjectBoxRecoveryRegion {
  /// Create a searialised [BaseRegion]
  ObjectBoxRecoveryRegion({
    required this.typeId,
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
    required this.multiLinkedRegions,
  });

  /// Create a searialised [BaseRegion]
  ///
  /// If representing a [MultiRegion], then [multiLinkedRegions] must be filled
  /// manually.
  ObjectBoxRecoveryRegion.fromRegion({required BaseRegion region})
      : typeId = switch (region) {
          RectangleRegion() => 0,
          CircleRegion() => 1,
          LineRegion() => 2,
          CustomPolygonRegion() => 3,
          MultiRegion() => 4,
        },
        rectNwLat =
            region is RectangleRegion ? region.bounds.northWest.latitude : null,
        rectNwLng = region is RectangleRegion
            ? region.bounds.northWest.longitude
            : null,
        rectSeLat =
            region is RectangleRegion ? region.bounds.southEast.latitude : null,
        rectSeLng = region is RectangleRegion
            ? region.bounds.southEast.longitude
            : null,
        circleCenterLat =
            region is CircleRegion ? region.center.latitude : null,
        circleCenterLng =
            region is CircleRegion ? region.center.longitude : null,
        circleRadius = region is CircleRegion ? region.radius : null,
        lineLats = region is LineRegion
            ? region.line.map((c) => c.latitude).toList(growable: false)
            : null,
        lineLngs = region is LineRegion
            ? region.line.map((c) => c.longitude).toList(growable: false)
            : null,
        lineRadius = region is LineRegion ? region.radius : null,
        customPolygonLats = region is CustomPolygonRegion
            ? region.outline.map((c) => c.latitude).toList(growable: false)
            : null,
        customPolygonLngs = region is CustomPolygonRegion
            ? region.outline.map((c) => c.longitude).toList(growable: false)
            : null,
        multiLinkedRegions = ToMany();

  /// ObjectBox ID
  @Id()
  @internal
  int id = 0;

  /// Corresponds to the generic type of [DownloadableRegion]
  ///
  /// Values must be as follows:
  /// * 0: rect
  /// * 1: circle
  /// * 2: line
  /// * 3: custom polygon
  /// * 4: multi
  final int typeId;

  /// Corresponds to [RectangleRegion.bounds]
  final double? rectNwLat;

  /// Corresponds to [RectangleRegion.bounds]
  final double? rectNwLng;

  /// Corresponds to [RectangleRegion.bounds]
  final double? rectSeLat;

  /// Corresponds to [RectangleRegion.bounds]
  final double? rectSeLng;

  /// Corresponds to [CircleRegion.center]
  final double? circleCenterLat;

  /// Corresponds to [CircleRegion.center]
  final double? circleCenterLng;

  /// Corresponds to [CircleRegion.radius]
  final double? circleRadius;

  /// Corresponds to [LineRegion.line]
  final List<double>? lineLats;

  /// Corresponds to [LineRegion.line]
  final List<double>? lineLngs;

  /// Corresponds to [LineRegion.radius]
  final double? lineRadius;

  /// Corresponds to [CustomPolygonRegion.outline]
  final List<double>? customPolygonLats;

  /// Corresponds to [CustomPolygonRegion.outline]
  final List<double>? customPolygonLngs;

  /// Corresponds to [MultiRegion.regions]
  final ToMany<ObjectBoxRecoveryRegion> multiLinkedRegions;

  /// Convert to a [BaseRegion]
  ///
  /// Will read from [multiLinkedRegions] if is a [MultiRegion].
  BaseRegion toRegion() => switch (typeId) {
        0 => RectangleRegion(
            LatLngBounds(
              LatLng(rectNwLat!, rectNwLng!),
              LatLng(rectSeLat!, rectSeLng!),
            ),
          ),
        1 => CircleRegion(
            LatLng(circleCenterLat!, circleCenterLng!),
            circleRadius!,
          ),
        2 => LineRegion(
            List.generate(
              lineLats!.length,
              (i) => LatLng(lineLats![i], lineLngs![i]),
            ),
            lineRadius!,
          ),
        3 => CustomPolygonRegion(
            List.generate(
              customPolygonLats!.length,
              (i) => LatLng(
                customPolygonLats![i],
                customPolygonLngs![i],
              ),
            ),
          ),
        4 => MultiRegion(
            multiLinkedRegions.map((r) => r.toRegion()).toList(growable: false),
          ),
        _ => throw UnimplementedError('Unpossible'),
      };
}
