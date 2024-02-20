// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages the download recovery of all sub-stores of this [FMTCRoot]
///
/// ---
///
/// When a download is started, a recovery region is stored in a database, and
/// the download ID is stored in memory (in a singleton to ensure it is never
/// disposed except when the application is closed).
///
/// If the download finishes normally, both entries are removed, otherwise, the
/// memory is cleared when the app is closed, but the database record is not
/// removed.
///
/// {@template fmtc.rootRecovery.failedDefinition}
/// A failed download is one that was found in the recovery database, but not
/// in the application memory. It can therefore be assumed that the download
/// is also no longer in memory, and therefore stopped unexpectedly.
/// {@endtemplate}
class RootRecovery {
  static RootRecovery? _instance;
  RootRecovery._() {
    _instance = this;
  }

  /// Determines which downloads are known to be on-going, and therefore
  /// can be ignored when fetching [recoverableRegions]
  final Set<int> _downloadsOngoing = {};

  /// List all recoverable regions, and whether each one has failed
  ///
  /// Result can be filtered to only include failed downloads using the
  /// [FMTCRecoveryGetFailedExts.failedOnly] extension.
  ///
  /// {@macro fmtc.rootRecovery.failedDefinition}
  Future<Iterable<({bool isFailed, RecoveredRegion region})>>
      get recoverableRegions async =>
          FMTCBackendAccess.internal.listRecoverableRegions().then(
                (rs) => rs.map(
                  (r) =>
                      (isFailed: !_downloadsOngoing.contains(r.id), region: r),
                ),
              );

  /// Get a specific region, even if it doesn't need recovering
  ///
  /// Returns `Future<null>` if there was no region found
  Future<({bool isFailed, RecoveredRegion region})?> getRecoverableRegion(
    int id,
  ) async {
    final region =
        await FMTCBackendAccess.internal.getRecoverableRegion(id: id);

    return (isFailed: !_downloadsOngoing.contains(region.id), region: region);
  }

  Future<void> _start({
    required int id,
    required String storeName,
    required DownloadableRegion region,
  }) async {
    _downloadsOngoing.add(id);
    await FMTCBackendAccess.internal
        .startRecovery(id: id, storeName: storeName, region: region);
  }

  /// {@macro fmtc.backend.cancelRecovery}
  Future<void> cancel(int id) async =>
      FMTCBackendAccess.internal.cancelRecovery(id: id);
}

/// Contains [failedOnly] extension for [RootRecovery.recoverableRegions]
///
/// See documentation on those methods for more information.
extension FMTCRecoveryGetFailedExts
    on Iterable<({bool isFailed, RecoveredRegion region})> {
  /// Filter the [RootRecovery.recoverableRegions] result to include only
  /// failed downloads
  Iterable<RecoveredRegion> get failedOnly =>
      where((r) => r.isFailed).map((r) => r.region);
}
