// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../../flutter_map_tile_caching.dart';
import '../export_internal.dart';

/// {@template fmtc.backend.backend}
/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// See also [FMTCBackendInternal], which has the actual method signatures. This
/// is provided as a means to warn users to avoid using the backend directly.
///
/// To implementers:
///  * Provide a seperate [FMTCBackend] & [FMTCBackendInternal] implementation
///    (both public scope), and a private scope `FMTCBackendImpl`
///  * Always make [FMTCBackendInternal] a singleton 'cover-up' for
///    `FMTCBackendImpl`, without a constructor
///  * Prefer throwing included implementation-generic errors/exceptions
///  * Ensure the [FMTCBackendInternal]/impl can be sent through isolates
///  * Always set the [FMTCBackendAccess.internal] property as necessary
///
/// See the default [FMTCObjectBoxBackend] implementation for an example.
/// {@endtemplate}
abstract interface class FMTCBackend<Internal extends FMTCBackendInternal> {
  /// {@macro fmtc.backend.backend}
  ///
  /// This constructor does not initialise this backend, also invoke
  /// [initialise].
  const FMTCBackend();

  /// {@template fmtc.backend.inititialise}
  /// Initialise this backend, and create the root
  ///
  /// Prefer to leave [rootDirectory] as null, which will use
  /// `getApplicationDocumentsDirectory()`. Alternatively, pass a custom
  /// directory - it is recommended to not use a typical cache directory, as the
  /// OS can clear these without notice at any time.
  /// {@endtemplate}
  Future<void> initialise({
    String? rootDirectory,
  });

  /// {@template fmtc.backend.uninitialise}
  /// Uninitialise this backend, and release whatever resources it is consuming
  ///
  /// If [deleteRoot] is `true`, then the root will be permanently deleted.
  /// {@endtemplate}
  Future<void> uninitialise({
    bool deleteRoot = false,
  });
}

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// Methods with a doc template in the doc string are for 'direct' public
/// invocation.
///
/// See [FMTCBackend] for more information.
abstract interface class FMTCBackendInternal with FMTCBackendAccess {
  const FMTCBackendInternal._();

  /// Generic description/name of this backend
  abstract final String friendlyIdentifier;

  /// The filesystem directory in use
  ///
  /// May also be used as an indicator as to whether the root has been
  /// initialised.
  Directory? get rootDirectory;

  /// {@template fmtc.backend.rootSize}
  /// Retrieve the total number of KiBs of all tiles' bytes (not 'real total'
  /// size) from all stores
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

  /// {@template fmtc.backend.storeExists}
  /// Check whether the specified store currently exists
  /// {@endtemplate}
  Future<bool> storeExists({
    required String storeName,
  });

  /// {@template fmtc.backend.createStore}
  /// Create a new store with the specified name
  /// {@endtemplate}
  Future<void> createStore({
    required String storeName,
  });

  /// {@template fmtc.backend.deleteStore}
  /// Delete the specified store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
  /// {@endtemplate}
  Future<void> deleteStore({
    required String storeName,
  });

  /// {@template fmtc.backend.resetStore}
  /// Remove all the tiles from within the specified store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
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

  /// Check whether the specified tile exists in the specified store
  Future<bool> tileExistsInStore({
    required String storeName,
    required String url,
  });

  /// Retrieve a raw tile by the specified URL
  Future<BackendTile?> readTile({
    required String url,
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
  /// If the tile already existed, it will be added to the specified store.
  /// Otherwise, [bytes] must be specified, and the tile will be created and
  /// added.
  ///
  /// If [bytes] is provided and the tile already existed, it will be updated for
  /// all stores.
  Future<void> writeTile({
    required String storeName,
    required String url,
    required Uint8List? bytes,
  });

  /// Create multiple tiles (given given their respective [urls] and [bytess]) in
  /// the specified store
  ///
  /// Logic is much simpler than [writeTile] and designed to be faster to allow
  /// for high bulk downloading throughputs.
  ///
  /// Existing tiles will always be overwritten if they exist.
  Future<void> writeTilesDirect({
    required String storeName,
    required List<String> urls,
    required List<Uint8List> bytess,
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
  Future<bool?> deleteTile({
    required String storeName,
    required String url,
  });

  /// Register a cache hit or miss on the specified store
  Future<void> registerHitOrMiss({
    required String storeName,
    required bool hit,
  });

  // TODO: Verify below and add to belower doc string
  //
  // It is recommended to invoke this operation as few times as possible, for
  // example by debouncing, as this operation may be expensive.

  /// Remove tiles in excess of the specified limit from the specified store,
  /// oldest first
  ///
  /// Returns the number of tiles that were actually deleted (they were
  /// orphaned). See [deleteTile] for more information about orphan tiles.
  Future<int> removeOldestTilesAboveLimit({
    required String storeName,
    required int tilesLimit,
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
  /// Note that this operation will override the stored value if there is already
  /// a matching key present.
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
  /// Note that this operation will override the stored value if there is already
  /// a matching key present.
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

  /// Create a recovery store with a recoverable region from the specified
  /// components
  Future<void> startRecovery({
    required int id,
    required String storeName,
    required DownloadableRegion region,
  });

  /// {@template fmtc.backend.cancelRecovery}
  /// Safely cancel the specified recoverable region
  /// {@endtemplate}
  Future<void> cancelRecovery({
    required int id,
  });
}
