// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../backend.dart';

typedef _IncomingCmd = ({int id, _CmdType type, Map<String, dynamic> args});

enum _CmdType {
  initialise_, // Only valid as a request
  destroy,
  realSize,
  rootSize,
  rootLength,
  listStores,
  storeGetMaxLength,
  storeSetMaxLength,
  storeExists,
  createStore,
  resetStore,
  renameStore,
  deleteStore,
  getStoreStats,
  tileExists,
  readTile,
  readLatestTile,
  writeTile,
  deleteTile,
  incrementStoreHits,
  incrementStoreMisses,
  removeOldestTilesAboveLimit,
  removeTilesOlderThan,
  readMetadata,
  setBulkMetadata,
  removeMetadata,
  resetMetadata,
  listRecoverableRegions,
  getRecoverableRegion,
  cancelRecovery,
  watchRecovery(hasInternalStreamSub: true),
  watchStores(hasInternalStreamSub: true),
  exportStores,
  importStores(hasInternalStreamSub: false),
  listImportableStores,
  cancelInternalStreamSub;

  const _CmdType({this.hasInternalStreamSub});

  /// Whether this command streams multiple results back
  ///
  /// If `true`, then this command does stream results, and it has an internal
  /// [StreamSubscription] that should be cancelled (using
  /// [cancelInternalStreamSub]) when it no longer needs to stream results.
  ///
  /// If `false`, then this command does stream results, but has no stream sub
  /// to be cancelled.
  ///
  /// If `null`, then this command does not stream results, and just returns a
  /// single result.
  final bool? hasInternalStreamSub;
}
