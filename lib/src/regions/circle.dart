// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// A geographically circular region based off a [center] coord and [radius]
///
/// It can be converted to a:
///  - [DownloadableRegion] for downloading: [toDownloadable]
///  - list of [LatLng]s forming the outline: [toOutline]
class CircleRegion extends BaseRegion {
  /// A geographically circular region based off a [center] coord and [radius]
  ///
  /// It can be converted to a:
  ///  - [DownloadableRegion] for downloading: [toDownloadable]
  ///  - list of [LatLng]s forming the outline: [toOutline]
  const CircleRegion(this.center, this.radius);

  /// Center coordinate
  final LatLng center;

  /// Radius in kilometers
  final double radius;

  @override
  DownloadableRegion<CircleRegion> toDownloadable({
    required int minZoom,
    required int maxZoom,
    required TileLayer options,
    int start = 1,
    int? end,
    Crs crs = const Epsg3857(),
  }) =>
      DownloadableRegion._(
        this,
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: options,
        start: start,
        end: end,
        crs: crs,
      );

  @override
  Iterable<LatLng> toOutline() sync* {
    const dist = Distance(roundResult: false, calculator: Haversine());

    final radius = this.radius * 1000;

    for (int angle = -180; angle <= 180; angle++) {
      yield dist.offset(center, radius, angle);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CircleRegion &&
          other.center == center &&
          other.radius == radius);

  @override
  int get hashCode => Object.hash(center, radius);
}
