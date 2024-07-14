// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../../flutter_map_tile_caching.dart';
import '../../export_internal.dart';

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root), from a 'normal' thread (likely the UI thread)
///
/// Should implement methods that operate in another isolate/thread to avoid
/// blocking the normal thread. In this case, [FMTCBackendInternalThreadSafe]
/// should also be implemented, which should not operate in another thread & must
/// be sendable between isolates (because it will already be operated in another
/// thread), and must be suitable for simultaneous initialisation across multiple
/// threads.
///
/// Should be set in [FMTCBackendAccess] when ready to use, and unset when not.
/// See documentation on that class for more information.
///
/// Methods with a doc template in the doc string are for 'direct' public
/// invocation.
///
/// See [FMTCBackend] for more information.
abstract interface class FMTCBackendInternal
    with FMTCBackendAccess, FMTCBackendAccessThreadSafe {
  const FMTCBackendInternal._();

  /// Generic description/name of this backend
  abstract final String friendlyIdentifier;

  /// {@template fmtc.backend.realSize}
  /// Retrieve the actual total size of the database in KiBs
  ///
  /// Should include 'unused' space, 'calculation' space, overheads, etc. May be
  /// much larger than `rootSize` in some backends.
  /// {@endtemplate}
  Future<double> realSize();

  /// {@template fmtc.backend.rootSize}
  /// Retrieve the total number of KiBs of all tiles' bytes (not 'real total'
  /// size) from all stores
  ///
  /// Does not include any storage used by metadata or database overheads, as in
  /// `realSize`.
  /// {@endtemplate}
  Future<double> rootSize();

  /// {@template fmtc.backend.rootLength}
  /// Retrieve the total number of tiles in all stores
  /// {@endtemplate}
  Future<int> rootLength();

  /// {@template fmtc.backend.listStores}
  /// List all the available stores
  /// {@endtemplate}
  Future<List<String>> listStores();

  /// {@template fmtc.backend.storeGetMaxLength}
  /// Retrieve the maximum allowable number of tiles within the specified store
  ///
  /// This limit is enforced automatically when browse caching, but not when
  /// bulk downloading.
  ///
  /// `null` means there is no configured limit.
  /// {@endtemplate}
  Future<int?> storeGetMaxLength({
    required String storeName,
  });

  /// {@template fmtc.backend.storeSetMaxLength}
  /// Set the maximum allowable number of tiles within the specified store
  ///
  /// This limit is enforced automatically when browse caching, but not when
  /// bulk downloading.
  ///
  /// Set `null` to disable the limit.
  /// {@endtemplate}
  Future<void> storeSetMaxLength({
    required String storeName,
    required int? newMaxLength,
  });

  /// {@template fmtc.backend.storeExists}
  /// Check whether the specified store currently exists
  /// {@endtemplate}
  Future<bool> storeExists({
    required String storeName,
  });

  /// {@template fmtc.backend.createStore}
  /// Create a new store with the specified name
  ///
  /// If set, [maxLength] will be the maximum allowed number of tiles in the
  /// store. This limit is enforced automatically when browse caching, but not
  /// when bulk downloading. Defaults to `null`: unlimited.
  ///
  /// Does nothing if the store already exists.
  /// {@endtemplate}
  Future<void> createStore({
    required String storeName,
    required int? maxLength,
  });

  /// {@template fmtc.backend.deleteStore}
  /// Delete the specified store
  ///
  /// > [!WARNING]
  /// > This operation cannot be undone! Ensure you confirm with the user that
  /// > this action is expected.
  ///
  /// Does nothing if the store does not already exist.
  /// {@endtemplate}
  Future<void> deleteStore({
    required String storeName,
  });

  /// {@template fmtc.backend.resetStore}
  /// Remove all the tiles from within the specified store
  ///
  /// Also resets the hits & misses stats. Does not reset any associated
  /// metadata.
  ///
  /// > [!WARNING]
  /// > This operation cannot be undone! Ensure you confirm with the user that
  /// > this action is expected.
  ///
  /// Does nothing if the store does not already exist.
  /// {@endtemplate}
  Future<void> resetStore({
    required String storeName,
  });

  /// {@template fmtc.backend.renameStore}
  /// Change the name of the specified store to the specified new store name
  /// {@endtemplate}
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  });

  /// {@template fmtc.backend.getStoreStats}
  /// Retrieve the following statistics about the specified store (all available):
  ///
  ///  * `size`: total number of KiBs of all tiles' bytes (not 'real total' size)
  ///  * `length`: number of tiles belonging
  ///  * `hits`: number of successful tile retrievals when browsing
  ///  * `misses`: number of unsuccessful tile retrievals when browsing
  /// {@endtemplate}
  Future<({double size, int length, int hits, int misses})> getStoreStats({
    required String storeName,
  });

  /// Check whether the specified tile exists in any of the specified stores (or
  /// any store is [storeNames] is `null`)
  Future<bool> tileExists({
    required String url,
    List<String>? storeNames,
  });

  /// Retrieve a raw `tile` from any of the specified [storeNames] (or all store
  /// names if `null` or empty) by the specified URL
  ///
  /// Returns the list of store names the tile belongs to - `allStoreNames` -
  /// and were present in [storeNames] if specified - `intersectedStoreNames`.
  ///
  /// If [storeNames] is `null` or empty, tiles may be retrieved from any store
  /// (which may be slower depending on the size of the root, as queries may
  /// be unconstrained).
  ///
  /// `intersectedStoreNames` & `allStoreNames` will be empty if `tile` is
  /// `null`.
  Future<
      ({
        BackendTile? tile,
        List<String> intersectedStoreNames,
        List<String> allStoreNames,
      })> readTile({
    required String url,
    List<String>? storeNames,
  });

  /// {@template fmtc.backend.readLatestTile}
  /// Retrieve the tile most recently modified in the specified store, if any
  /// tiles exist
  /// {@endtemplate}
  Future<BackendTile?> readLatestTile({
    required String storeName,
  });

  /// Create or update a tile (given a [url] and its [bytes]) in the specified
  /// store
  ///
  /// Returns all the stores that were written to, along with whether that tile
  /// was new to that store (not updated).
  Future<Map<String, bool>> writeTile({
    required String url,
    required Uint8List bytes,
    required List<String> storeNames,
    required List<String>? writeAllNotIn,
  });

  /// Remove the tile from the specified store, deleting it if was orphaned
  ///
  /// As tiles can belong to multiple stores, a tile cannot be safely 'truly'
  /// deleted unless it does not belong to any other stores (it was an orphan).
  /// A tile that is not an orphan will just be 'removed' from the specified
  /// store.
  ///
  /// Returns:
  ///  * `null` : if there was no existing tile
  ///  * `true` : if the tile itself could be deleted (it was orphaned)
  ///  * `false`: if the tile still belonged to at least one other store
  @visibleForTesting
  Future<bool?> deleteTile({
    required String storeName,
    required String url,
  });

  /// Register a cache hit or miss on the specified stores, or all stores if
  /// null or empty
  Future<void> registerHitOrMiss({
    required List<String>? storeNames,
    required bool hit,
  });

  /// Remove tiles in excess of the specified limit in each specified store,
  /// oldest tile first
  ///
  /// Should internally debounce, as this is a repeatedly invoked & potentially
  /// expensive operation, that will have no effect when the number of tiles in
  /// the store is below the limit.
  ///
  /// Returns the number of tiles that were actually deleted (they were
  /// orphaned (see [deleteTile] for more info)) for each store.
  ///
  /// If a store does not appear in the output, but was inputted, the store
  /// likely did not have a tile limit, in which case no tiles were removed.
  ///
  /// May throw [RootUnavailable] if the root is uninitialised whilst the
  /// debouncing mechanism is running.
  Future<Map<String, int>> removeOldestTilesAboveLimit({
    required List<String> storeNames,
  });

  /// {@template fmtc.backend.removeTilesOlderThan}
  /// Remove tiles that were last modified after expiry from the specified store
  ///
  /// Returns the number of tiles that were actually deleted (they were
  /// orphaned). See [deleteTile] for more information about orphan tiles.
  /// {@endtemplate}
  Future<int> removeTilesOlderThan({
    required String storeName,
    required DateTime expiry,
  });

  /// {@template fmtc.backend.readMetadata}
  /// Retrieve the stored metadata for the specified store
  /// {@endtemplate}
  Future<Map<String, String>> readMetadata({
    required String storeName,
  });

  /// {@template fmtc.backend.setMetadata}
  /// Set a key-value pair in the metadata for the specified store
  ///
  /// > [!WARNING]
  /// > Any existing value for the specified key will be overwritten.
  ///
  /// Prefer using [setBulkMetadata] when setting multiple keys. Only one backend
  /// operation is required to set them all at once, and so is more efficient.
  /// {@endtemplate}
  Future<void> setMetadata({
    required String storeName,
    required String key,
    required String value,
  });

  /// {@template fmtc.backend.setBulkMetadata}
  /// Set multiple key-value pairs in the metadata for the specified store
  ///
  /// Note that this operation will overwrite any existing value for each
  /// specified key.
  /// {@endtemplate}
  Future<void> setBulkMetadata({
    required String storeName,
    required Map<String, String> kvs,
  });

  /// {@template fmtc.backend.removeMetadata}
  /// Remove the specified key from the metadata for the specified store
  ///
  /// Returns the value associated with key before it was removed, or `null` if
  /// it was not present.
  /// {@endtemplate}
  Future<String?> removeMetadata({
    required String storeName,
    required String key,
  });

  /// {@template fmtc.backend.resetMetadata}
  /// Clear the metadata for the specified store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
  /// {@endtemplate}
  Future<void> resetMetadata({
    required String storeName,
  });

  /// List all registered recovery regions
  ///
  /// Not all regions are failed, requires the [RootRecovery] object to
  /// determine this.
  Future<List<RecoveredRegion>> listRecoverableRegions();

  /// Retrieve the specified registered recovery region
  ///
  /// Not all regions are failed, requires the [RootRecovery] object to
  /// determine this.
  Future<RecoveredRegion> getRecoverableRegion({
    required int id,
  });

  /// {@template fmtc.backend.cancelRecovery}
  /// Safely cancel the specified recoverable region
  /// {@endtemplate}
  Future<void> cancelRecovery({
    required int id,
  });

  /// {@template fmtc.backend.watchRecovery}
  /// Watch for changes to the recovery system
  ///
  /// Useful to update UI only when required, for example, in a `StreamBuilder`.
  /// Whenever this has an event, it is likely the other statistics will have
  /// changed.
  /// {@endtemplate}
  Stream<void> watchRecovery({
    required bool triggerImmediately,
  });

  /// {@template fmtc.backend.watchStores}
  /// Watch for changes in the specified stores
  ///
  /// Useful to update UI only when required, for example, in a `StreamBuilder`.
  /// Whenever this has an event, it is likely the other statistics will have
  /// changed.
  ///
  /// Emits an event every time a change is made to a store:
  ///  * a statistic change, which should include every time a tile is changed
  ///  * a metadata change
  /// {@endtemplate}
  Stream<void> watchStores({
    required List<String> storeNames,
    required bool triggerImmediately,
  });

  /// Create an archive at the file [path] containing the specifed stores and
  /// their respective tiles
  ///
  /// See [RootExternal] for more information about expected behaviour and
  /// errors.
  Future<void> exportStores({
    required String path,
    required List<String> storeNames,
  });

  /// Load the specified stores (or all stores if `null`) from the archive file
  /// at [path] into the current root, using [strategy] where there are
  /// conflicts
  ///
  /// See [RootExternal] for more information about expected behaviour and
  /// errors.
  ///
  /// See [ImportResult] for information about how to handle the response.
  ImportResult importStores({
    required String path,
    required ImportConflictStrategy strategy,
    required List<String>? storeNames,
  });

  /// Check the stores available inside the archive file at [path]
  ///
  /// See [RootExternal] for more information about expected behaviour and
  /// errors.
  Future<List<String>> listImportableStores({
    required String path,
  });
}
