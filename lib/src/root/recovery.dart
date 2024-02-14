// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages the download recovery of all sub-stores of this [FMTCRoot]
///
/// Is a singleton to ensure functioning as expected.
class RootRecovery {
  RootRecovery._() {
    instance = this;
  }

  Isar get _recovery => FMTCRegistry.instance.recoveryDatabase;

  /// Manages the download recovery of all sub-stores of this [FMTCRoot]
  ///
  /// Is a singleton to ensure functioning as expected.
  static RootRecovery? instance;

  /// Keeps a list of downloads that are ongoing, so they are not recoverable
  /// unnecessarily
  final List<int> _downloadsOngoing = [];

  /// Get a list of all recoverable regions
  ///
  /// See [failedRegions] for regions that correspond to failed/stopped downloads.
  Future<List<RecoveredRegion>> get recoverableRegions async =>
      (await _recovery.recovery.where().findAll())
          .map(
            (r) => RecoveredRegion._(
              id: r.id,
              storeName: r.storeName,
              time: r.time,
              type: r.type,
              bounds: r.type == RegionType.rectangle
                  ? LatLngBounds(
                      LatLng(r.nwLat!, r.nwLng!),
                      LatLng(r.seLat!, r.seLng!),
                    )
                  : null,
              center: r.type == RegionType.circle
                  ? LatLng(r.centerLat!, r.centerLng!)
                  : null,
              line: r.type == RegionType.line ||
                      r.type == RegionType.customPolygon
                  ? List.generate(
                      r.linePointsLat!.length,
                      (i) => LatLng(r.linePointsLat![i], r.linePointsLng![i]),
                    )
                  : null,
              radius: r.type != RegionType.rectangle
                  ? r.type == RegionType.circle
                      ? r.circleRadius!
                      : r.lineRadius!
                  : null,
              minZoom: r.minZoom,
              maxZoom: r.maxZoom,
              start: r.start,
              end: r.end,
            ),
          )
          .toList();

  /// Get a list of all recoverable regions that correspond to failed/stopped downloads
  ///
  /// See [recoverableRegions] for all regions.
  Future<List<RecoveredRegion>> get failedRegions async =>
      (await recoverableRegions)
          .where((r) => !_downloadsOngoing.contains(r.id))
          .toList();

  /// Get a specific region, even if it doesn't need recovering
  ///
  /// Returns `Future<null>` if there was no region found
  Future<RecoveredRegion?> getRecoverableRegion(int id) async =>
      (await recoverableRegions).singleWhereOrNull((r) => r.id == id);

  /// Get a specific region, only if it needs recovering
  ///
  /// Returns `Future<null>` if there was no region found
  Future<RecoveredRegion?> getFailedRegion(int id) async =>
      (await failedRegions).singleWhereOrNull((r) => r.id == id);

  Future<void> _start({
    required int id,
    required String storeName,
    required DownloadableRegion region,
  }) async {
    _downloadsOngoing.add(id);
    return _recovery.writeTxn(
      () => _recovery.recovery.put(
        DbRecoverableRegion(
          id: id,
          storeName: storeName,
          time: DateTime.now(),
          type: region.when(
            rectangle: (_) => RegionType.rectangle,
            circle: (_) => RegionType.circle,
            line: (_) => RegionType.line,
            customPolygon: (_) => RegionType.customPolygon,
          ),
          minZoom: region.minZoom,
          maxZoom: region.maxZoom,
          start: region.start,
          end: region.end,
          nwLat: region.originalRegion is RectangleRegion
              ? (region.originalRegion as RectangleRegion)
                  .bounds
                  .northWest
                  .latitude
              : null,
          nwLng: region.originalRegion is RectangleRegion
              ? (region.originalRegion as RectangleRegion)
                  .bounds
                  .northWest
                  .longitude
              : null,
          seLat: region.originalRegion is RectangleRegion
              ? (region.originalRegion as RectangleRegion)
                  .bounds
                  .southEast
                  .latitude
              : null,
          seLng: region.originalRegion is RectangleRegion
              ? (region.originalRegion as RectangleRegion)
                  .bounds
                  .southEast
                  .longitude
              : null,
          centerLat: region.originalRegion is CircleRegion
              ? (region.originalRegion as CircleRegion).center.latitude
              : null,
          centerLng: region.originalRegion is CircleRegion
              ? (region.originalRegion as CircleRegion).center.longitude
              : null,
          linePointsLat: region.originalRegion is LineRegion
              ? (region.originalRegion as LineRegion)
                  .line
                  .map((c) => c.latitude)
                  .toList()
              : region.originalRegion is CustomPolygonRegion
                  ? (region.originalRegion as CustomPolygonRegion)
                      .outline
                      .map((c) => c.latitude)
                      .toList()
                  : null,
          linePointsLng: region.originalRegion is LineRegion
              ? (region.originalRegion as LineRegion)
                  .line
                  .map((c) => c.longitude)
                  .toList()
              : region.originalRegion is CustomPolygonRegion
                  ? (region.originalRegion as CustomPolygonRegion)
                      .outline
                      .map((c) => c.longitude)
                      .toList()
                  : null,
          circleRadius: region.originalRegion is CircleRegion
              ? (region.originalRegion as CircleRegion).radius
              : null,
          lineRadius: region.originalRegion is LineRegion
              ? (region.originalRegion as LineRegion).radius
              : null,
        ),
      ),
    );
  }

  /// Safely cancel a recoverable region
  Future<void> cancel(int id) async {
    if (_downloadsOngoing.remove(id)) {
      return _recovery.writeTxn(() => _recovery.recovery.delete(id));
    }
  }
}
