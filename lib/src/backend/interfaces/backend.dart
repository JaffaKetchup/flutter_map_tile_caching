import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

import '../../../flutter_map_tile_caching.dart';
import '../impl_tools/errors.dart';
import 'models.dart';

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// To implementers:
///  * Use a public 'cover-up' and separate private implementation
///  * Use singletons (with a factory) to ensure consistent state management
///  * Prefer throwing included implementation-generic errors/exceptions
///
/// To end-users:
///  * Use [FMTCSettings.backend] to set a custom backend
///  * Not all sync versions of methods are guaranteed to have implementations
abstract interface class FMTCBackend {
  const FMTCBackend();

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
  void destroySync({
    bool deleteRoot = false,
  });

  /// Whether [destroySync] is implemented
  ///
  /// If `false`, calling will throw an [SyncOperationUnsupported] error.
  abstract final bool supportsSyncDestroy;

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

  Future<bool> removeOldestTile({
    required String storeName,
  });
}
