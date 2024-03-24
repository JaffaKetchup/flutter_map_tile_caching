// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Manage custom miscellaneous information tied to an [FMTCStore]
///
/// Uses a key-value format where both key and value must be [String]. More
/// advanced requirements should use another package, as this is a basic
/// implementation.
class StoreMetadata {
  StoreMetadata._(FMTCStore store) : _storeName = store.storeName;

  final String _storeName;

  /// {@macro fmtc.backend.readMetadata}
  Future<Map<String, String>> get read =>
      FMTCBackendAccess.internal.readMetadata(storeName: _storeName);

  /// {@macro fmtc.backend.setMetadata}
  Future<void> set({
    required String key,
    required String value,
  }) =>
      FMTCBackendAccess.internal
          .setMetadata(storeName: _storeName, key: key, value: value);

  /// {@macro fmtc.backend.setBulkMetadata}
  Future<void> setBulk({
    required Map<String, String> kvs,
  }) =>
      FMTCBackendAccess.internal
          .setBulkMetadata(storeName: _storeName, kvs: kvs);

  /// {@macro fmtc.backend.removeMetadata}
  Future<void> remove({
    required String key,
  }) =>
      FMTCBackendAccess.internal
          .removeMetadata(storeName: _storeName, key: key);

  /// {@macro fmtc.backend.resetMetadata}
  Future<void> reset() =>
      FMTCBackendAccess.internal.resetMetadata(storeName: _storeName);
}
