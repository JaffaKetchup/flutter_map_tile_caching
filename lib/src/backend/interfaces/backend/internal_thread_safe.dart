// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:typed_data';

import '../../export_external.dart';
import '../../export_internal.dart';

/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root), from an existing bulk downloading thread
///
/// Should implement methods that operate in the same thread. Must be sendable
/// between isolates, because it will be operated in another thread. Must be
/// suitable for simultaneous [initialise]ation across multiple threads.
///
/// Should be set-up ready for intialisation, and set in the
/// [FMTCBackendAccessThreadSafe], from the initialisation of
/// [FMTCBackendInternal]. See documentation on that class for more information.
///
/// Methods with a doc template in the doc string are for 'direct' public
/// invocation.
///
/// See [FMTCBackend] for more information.
abstract interface class FMTCBackendInternalThreadSafe {
  const FMTCBackendInternalThreadSafe._();

  /// Generic description/name of this backend
  abstract final String friendlyIdentifier;

  /// Start this thread safe database operator
  FutureOr<void> initialise();

  /// Stop this thread safe database operator
  FutureOr<void> uninitialise();

  /// Retrieve a raw tile by the specified URL
  ///
  /// If [storeName] is specified, the tile will be limited to the specified
  /// store - if it exists in another store, it will not be returned.
  FutureOr<BackendTile?> readTile({
    required String url,
    String? storeName,
  });

  /// Create or update a tile (given a [url] and its [bytes]) in the specified
  /// store
  ///
  /// Logic is simpler than the respective [FMTCBackendInternal.writeTile]
  /// method, and designed for high throughput: existing tiles will always be
  /// overwritten (if they exist).
  FutureOr<void> htWriteTile({
    required String storeName,
    required String url,
    required Uint8List bytes,
  });

  /// Create or update multiple tiles (given given their respective [urls] and
  /// [bytess]) in the specified store
  ///
  /// Designed for high throughput: existing tiles will always be overwritten
  /// (if they exist).
  FutureOr<void> htWriteTiles({
    required String storeName,
    required List<String> urls,
    required List<Uint8List> bytess,
  });
}
