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

  /// {@template fmtc.backend.initialise}
  /// Initialise this backend & create the root
  ///
  /// [rootDirectory] defaults to '[getApplicationDocumentsDirectory]/fmtc'.
  ///
  /// [maxDatabaseSize] defaults to 1 GB shared across all stores. Specify the
  /// amount in KB.
  ///
  /// Some implementations may accept/require additional arguments that may
  /// be set through [implSpecificArgs]. See their documentation for more
  /// information.
  /// {@endtemplate}
  ///
  /// ---
  ///
  /// Note to implementers: if you accept implementation specific arguments,
  /// ensure you properly document these.
  Future<void> initialise({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  });

  /// {@template fmtc.backend.destroy}
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
  /// {@endtemplate}
  Future<void> destroy({
    required bool deleteRoot,
    required bool immediate,
  });

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

  /// Change the name of the store named [currentStoreName] to [newStoreName]
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  });

  /// {@template fmtc.backend.getStoreSize}
  /// Retrieve the total size (in kibibytes KiB) of the image bytes of all the
  /// tiles that belong to the specified store
  ///
  /// This does not return any other data that adds to the 'real' store size.
  /// {@endtemplate}
  Future<double> getStoreSize({
    required String storeName,
  });

  /// {@template fmtc.backend.getStoreLength}
  /// Retrieve the number of tiles that belong to the specified store
  /// {@endtemplate}
  Future<int> getStoreLength({
    required String storeName,
  });

  /// {@template fmtc.backend.getStoreHits}
  /// Retrieve the number of times that a tile was successfully retrieved from
  /// the specified store when browsing
  /// {@endtemplate}
  Future<int> getStoreHits({
    required String storeName,
  });

  /// {@template fmtc.backend.getStoreMisses}
  /// Retrieve the number of times that a tile was attempted to be retrieved from
  /// the specified store when browsing, but was not present
  /// {@endtemplate}
  Future<int> getStoreMisses({
    required String storeName,
  });

  /// Get a raw tile by URL
  Future<BackendTile?> readTile({
    required String url,
  });

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

  /// {@template fmtc.backend.removeOldestTile}
  /// Remove the specified number of tiles from the specified store, in the order
  /// of oldest first, and where each tile does not belong to any other store
  /// {@endtemplate}
  Future<void> removeOldestTile({
    required String storeName,
    required int numToRemove,
  });
}
