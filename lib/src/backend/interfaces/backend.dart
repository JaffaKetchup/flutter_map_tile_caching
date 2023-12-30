import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

import '../../../flutter_map_tile_caching.dart';

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// See also [FMTCBackendInternal], which has the actual methods. This is
/// provided as a means to warn users to avoid using the backend directly.
///
/// To implementers:
///  * Provide a seperate [FMTCBackend] & [FMTCBackendInternal] implementation
///    (both public scope), and a private scope `FMTCBackendImpl`
///  * Annotate your [FMTCBackend.internal] method with '@internal'
///  * Always make [FMTCBackendInternal] a singleton 'cover-up' for
///    `FMTCBackendImpl`, without a constructor, as the `FMTCBackendImpl` will
///    be accessed via [FMTCBackend.internal]
///  * Prefer throwing included implementation-generic errors/exceptions
///
/// To end-users:
///  * Use [FMTCSettings.backend] to set a custom backend
///  * Not all sync versions of methods are guaranteed to have implementations
///  * Avoid calling the [internal] method of a backend
abstract interface class FMTCBackend<Internal extends FMTCBackendInternal> {
  const FMTCBackend();

  @protected
  Internal get internal;
}

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// See [FMTCBackend] for more information.
abstract interface class FMTCBackendInternal {
  abstract final String friendlyIdentifier;

  /// {@template fmtc_backend_initialise}
  /// Initialise this backend & create the root
  ///
  /// [rootDirectory] defaults to '[getApplicationDocumentsDirectory]/fmtc'.
  ///
  /// [maxDatabaseSize] defaults to 1 GB shared across all stores. Specify the
  /// amount in KB.
  /// {@endtemplate}
  ///
  /// Some implementations may accept/require additional arguments that may
  /// be set through [implSpecificArgs]. See their documentation for more
  /// information.
  ///
  /// ---
  ///
  /// Note to implementers: if you accept implementation specific arguments,
  /// override the documentation on this method, and use the
  /// 'fmtc_backend_initialise' macro at the top to retain the standard docs.
  Future<void> initialise({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  });

  /// {@macro fmtc_backend_initialise}
  ///
  /// ---
  ///
  /// Note to implementers: if you accept implementation specific arguments,
  /// override the documentation on this method, and use the
  /// 'fmtc_backend_initialise' macro at the top to retain the standard docs.
  void initialiseSync({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  });

  /// Whether [initialiseSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncInitialise;

  /// Uninitialise this backend, and release whatever resources it is consuming
  ///
  /// If [deleteRoot] is `true`, then the storage medium will be permanently
  /// deleted.
  Future<void> destroy({
    bool deleteRoot = false,
  });

  /// Uninitialise this backend, and release whatever resources it is consuming
  ///
  /// If [deleteRoot] is `true`, then the storage medium will be permanently
  /// deleted.
  ///
  /// If [immediate] is `true`, any operations currently underway will be lost.
  /// If `false`, all operations currently underway will be allowed to complete,
  /// but any operations started after this method call will be lost. A lost
  /// operation may throw [RootUnavailable]. This parameter may not have a
  /// noticable/any effect in some implementations.
  void destroySync({
    bool deleteRoot = false,
    bool immediate = false,
  });

  /// Whether [destroySync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncDestroy;

  /// Whether the store currently exists
  Future<bool> storeExists({
    required String storeName,
  });

  /// Whether the store currently exists
  bool storeExistsSync({
    required String storeName,
  });

  /// Whether [storeExistsSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncStoreExists;

  /// Create a new store with the specified name
  Future<void> createStore({
    required String storeName,
  });

  /// Create a new store with the specified name
  void createStoreSync({
    required String storeName,
  });

  /// Whether [createStoreSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncCreateStore;

  /// Remove all the tiles from within the specified store
  Future<void> resetStore({
    required String storeName,
  });

  /// Remove all the tiles from within the specified store
  void resetStoreSync({
    required String storeName,
  });

  /// Whether [resetStoreSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncResetStore;

  /// Change the name of the store named [currentStoreName] to [newStoreName]
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  });

  /// Change the name of the store named [currentStoreName] to [newStoreName]
  void renameStoreSync({
    required String currentStoreName,
    required String newStoreName,
  });

  /// Whether [renameStoreSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncRenameStore;

  /// Delete the specified store
  Future<void> deleteStore({
    required String storeName,
  });

  /// Delete the specified store
  void deleteStoreSync({
    required String storeName,
  });

  /// Whether [deleteStoreSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncDeleteStore;

  /// Retrieve the total size (in kibibytes KiB) of the image bytes of all the
  /// tiles that belong to the specified store
  ///
  /// This does not return any other data that adds to the 'real' store size
  Future<double> getStoreSize({
    required String storeName,
  });

  /// Retrieve the total size (in kibibytes KiB) of the image bytes of all the
  /// tiles that belong to the specified store
  ///
  /// This does not return any other data that adds to the 'real' store size
  double getStoreSizeSync({
    required String storeName,
  });

  /// Whether [getStoreSizeSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncGetStoreSize;

  /// Retrieve the number of tiles that belong to the specified store
  Future<int> getStoreLength({
    required String storeName,
  });

  /// Retrieve the number of tiles that belong to the specified store
  int getStoreLengthSync({
    required String storeName,
  });

  /// Whether [getStoreLengthSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncGetStoreLength;

  /// Retrieve the number of times that a tile was successfully retrieved from
  /// the specified store when browsing
  Future<int> getStoreHits({
    required String storeName,
  });

  /// Retrieve the number of times that a tile was successfully retrieved from
  /// the specified store when browsing
  int getStoreHitsSync({
    required String storeName,
  });

  /// Whether [getStoreHitsSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncGetStoreHits;

  /// Retrieve the number of times that a tile was attempted to be retrieved from
  /// the specified store when browsing, but was not present
  Future<int> getStoreMisses({
    required String storeName,
  });

  /// Retrieve the number of times that a tile was attempted to be retrieved from
  /// the specified store when browsing, but was not present
  int getStoreMissesSync({
    required String storeName,
  });

  /// Whether [getStoreMissesSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncGetStoreMisses;

  /// Get a raw tile by URL
  Future<BackendTile?> readTile({
    required String url,
  });

  /// Get a raw tile by URL
  BackendTile? readTileSync({
    required String url,
  });

  /// Whether [readTileSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncReadTile;

  /// Create or update a tile
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

  /// Create or update a tile
  ///
  /// If the tile already existed, it will be added to the specified store.
  /// Otherwise, [bytes] must be specified, and the tile will be created and
  /// added.
  ///
  /// If [bytes] is provided and the tile already existed, it will be updated for
  /// all stores.
  void writeTileSync({
    required String storeName,
    required String url,
    required Uint8List? bytes,
  });

  /// Whether [writeTileSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncWriteTile;

  /// Remove the tile from the store, deleting it if orphaned
  ///
  /// Returns:
  ///  * `null` : if there was no existing tile
  ///  * `true` : if the tile itself could be deleted (it was orphaned)
  ///  * `false`: if the tile still belonged to at least store
  Future<bool?> deleteTile({
    required String storeName,
    required String url,
  });

  /// Remove the tile from the store, deleting it if orphaned
  ///
  /// Returns:
  ///  * `null` : if there was no existing tile
  ///  * `true` : if the tile itself could be deleted (it was orphaned)
  ///  * `false`: if the tile still belonged to at least store
  bool? deleteTileSync({
    required String storeName,
    required String url,
  });

  /// Whether [deleteTileSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncDeleteTile;

  Future<void> removeOldestTile({
    required String storeName,
  });

  void removeOldestTileSync({
    required String storeName,
  });

  /// Whether [removeOldestTileSync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncRemoveOldestTile;
}
