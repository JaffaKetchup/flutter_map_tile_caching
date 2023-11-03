import 'dart:async';

import 'package:meta/meta.dart';

import '../../../flutter_map_tile_caching.dart';
import 'models.dart';

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// To implementers:
///  * Use singletons (with a factory) to ensure consistent state management
///  * Prefer throwing included implementation-generic errors/exceptions
///  * Mark all attributes/methods `@internal`, except the factory
///
/// To end-users:
/// * Use [FMTCSettings.backend] to set a custom backend
/// * Only the constructor ([FMTCBackend.new]) of an implementation should be
/// used in end applications
abstract interface class FMTCBackend {
  const FMTCBackend();

  abstract final String friendlyIdentifier;

  @internal
  abstract final bool supportsSharing;

  @internal
  FutureOr<void> initialise({
    String? rootDirectory,
  });
  @internal
  FutureOr<void> destroy({
    bool deleteRoot = false,
  });

  @internal
  FutureOr<void> createStore({
    required String storeName,
  });
  @internal
  FutureOr<void> resetStore({
    required String storeName,
  });
  @internal
  FutureOr<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  });
  @internal
  FutureOr<void> deleteStore({
    required String storeName,
  });

  @internal
  Future<List<BackendTile>> readTile({required String url});
  @internal
  FutureOr<void> createTile();
  @internal
  FutureOr<void> updateTile();
  @internal
  FutureOr<void> deleteTile();

  @internal
  FutureOr<void> readLatestTile();
  @internal
  FutureOr<void> pruneTilesOlderThan({required DateTime expiry});
}
