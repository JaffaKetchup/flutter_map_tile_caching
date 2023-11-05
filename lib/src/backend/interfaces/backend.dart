import 'dart:async';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../flutter_map_tile_caching.dart';
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
  FutureOr<void> initialise({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  });
  FutureOr<void> destroy({
    bool deleteRoot = false,
  });

  FutureOr<void> createStore({
    required String storeName,
  });
  FutureOr<void> resetStore({
    required String storeName,
  });
  FutureOr<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  });
  FutureOr<void> deleteStore({
    required String storeName,
  });

  /// Get a raw tile by URL
  FutureOr<BackendTile?> readTile({
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
  FutureOr<void> createTile({
    required String url,
    required Uint8List? bytes,
    required String storeName,
  });

  /// Remove the tile from the store, deleting it if orphaned
  ///
  /// Returns:
  ///  * `null` : if there was no existing tile
  ///  * `true` : if the tile itself could be deleted (it was orphaned)
  ///  * `false`: if the tile still belonged to at least store
  FutureOr<bool?> deleteTile({
    required String url,
    required String storeName,
  });
}
