// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manage custom miscellaneous information tied to a [FMTCStore]
///
/// Uses a key-value format where both key and value must be [String]. More
/// advanced requirements should use another package, as this is a basic
/// implementation.
class StoreMetadata extends _WithBackendAccess {
  const StoreMetadata._(super._store);

  /// Add a new key-value pair to the store asynchronously
  ///
  /// Overwrites the value if the key already exists.
  Future<void> addAsync({required String key, required String value}) =>
      _db.writeTxn(() => _db.metadata.put(DbMetadata(name: key, data: value)));

  /// Add a new key-value pair to the store synchronously
  ///
  /// Overwrites the value if the key already exists.
  ///
  /// Prefer [addAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  void add({required String key, required String value}) => _db.writeTxnSync(
        () => _db.metadata.putSync(DbMetadata(name: key, data: value)),
      );

  /// Remove a new key-value pair from the store asynchronously
  Future<void> removeAsync({required String key}) =>
      _db.writeTxn(() => _db.metadata.delete(DatabaseTools.hash(key)));

  /// Remove a new key-value pair from the store synchronously
  ///
  /// Prefer [removeAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  void remove({required String key}) => _db.writeTxnSync(
        () => _db.metadata.deleteSync(DatabaseTools.hash(key)),
      );

  /// Remove all the key-value pairs from the store asynchronously
  Future<void> resetAsync() => _db.writeTxn(
        () async => Future.wait(
          (await _db.metadata.where().findAll())
              .map((m) => _db.metadata.delete(m.id)),
        ),
      );

  /// Remove all the key-value pairs from the store synchronously
  ///
  /// Prefer [resetAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  void reset() => _db.writeTxnSync(
        () => Future.wait(
          _db.metadata
              .where()
              .findAllSync()
              .map((m) => _db.metadata.delete(m.id)),
        ),
      );

  /// Read all the key-value pairs from the store asynchronously
  Future<Map<String, String>> get readAsync async => Map.fromEntries(
        (await _db.metadata.where().findAll())
            .map((m) => MapEntry(m.name, m.data)),
      );

  /// Read all the key-value pairs from the store synchronously
  ///
  /// Prefer [readAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  Map<String, String> get read => Map.fromEntries(
        _db.metadata.where().findAllSync().map((m) => MapEntry(m.name, m.data)),
      );
}
