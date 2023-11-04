import 'dart:async';
import 'dart:typed_data';

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
/// * Use [FMTCSettings.backend] to set a custom backend
abstract interface class FMTCBackend {
  const FMTCBackend();

  abstract final String friendlyIdentifier;

  FutureOr<void> initialise({
    String? rootDirectory,
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

  FutureOr<BackendTile?> readTile({
    required String url,
  });
  FutureOr<void> createTile({
    required String url,
    required Uint8List bytes,
    required String storeName,
  });
  FutureOr<bool?> deleteTile({
    required String url,
    required String storeName,
  });
}
