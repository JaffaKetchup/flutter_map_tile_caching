// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Manages the download recovery of all sub-stores of this [FMTCRoot]
///
/// ---
///
/// When a download is started, a recovery region is stored in a non-volatile
/// database, and the download ID is stored in volatile memory.
///
/// If the download finishes normally, both entries are removed, otherwise, the
/// memory is cleared when the app is closed, but the database record is not
/// removed.
///
/// {@template fmtc.rootRecovery.failedDefinition}
/// A failed download is one that was found in the recovery database, but not
/// in the application memory. It can therefore be assumed that the download
/// is also no longer in memory, and was therefore stopped unexpectedly, for
/// example after a fatal crash.
/// {@endtemplate}
///
/// The recovery system then allows the original [BaseRegion] and
/// [DownloadableRegion] to be recovered (via [RecoveredRegion]) from the failed
/// download, and the download can be restarted.
///
/// During a download, the database recovery entity is updated every tile (or
/// every batch) with the number of completed tiles: this allows the
/// [DownloadableRegion.start] to have it's value set to skip tiles that have
/// been successfully downloaded. Therefore, no unnecessary tiles are downloaded
/// again.
///
/// > [!NOTE]
/// > Options set at download time, in [StoreDownload.startForeground], are not
/// > included.
class RootRecovery {
  factory RootRecovery._() => _instance ??= const RootRecovery._uninstanced({});
  const RootRecovery._uninstanced(Set<int> downloadsOngoing)
      : _downloadsOngoing = downloadsOngoing;
  static RootRecovery? _instance;

  /// Determines which downloads are known to be on-going, and therefore
  /// can be ignored when fetching [recoverableRegions]
  final Set<int> _downloadsOngoing;

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
