// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../fmtc.dart';

/// Manage custom miscellaneous information tied to a [StoreDirectory]
///
/// Uses a key-value format where both key and value must be [String]. More
/// advanced requirements should use another package, as this is a basic
/// implementation.
@internal
class StoreMetadata {
  StoreMetadata._(StoreDirectory storeDirectory)
      : _id = DatabaseTools.hash(storeDirectory.storeName);
  final int _id;

  Isar get _metadata => FMTCRegistry.instance.tileDatabases[_id]!;

  /// Add a new key-value pair to the store
  ///
  /// Overwrites the value if the key already exists.
  Future<void> addAsync({
    required String key,
    required String value,
  }) =>
      _metadata.writeTxn(
        () => _metadata.metadata.put(DbMetadata(name: key, data: value)),
      );

  /// Add a new key-value pair to the store
  ///
  /// Overwrites the value if the key already exists.
  ///
  /// Prefer [addAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  void add({
    required String key,
    required String value,
  }) =>
      _metadata.writeTxnSync(
        () => _metadata.metadata.putSync(DbMetadata(name: key, data: value)),
      );

  /// Remove a new key-value pair from the store
  Future<void> removeAsync({required String key}) => _metadata
      .writeTxn(() => _metadata.metadata.delete(DatabaseTools.hash(key)));

  /// Remove a new key-value pair from the store
  ///
  /// Prefer [removeAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  void remove({required String key}) => _metadata.writeTxnSync(
        () => _metadata.metadata.deleteSync(DatabaseTools.hash(key)),
      );

  /// Remove all the key-value pairs from the store asynchronously
  Future<void> resetAsync() => _metadata.writeTxn(
        () async => Future.wait(
          (await _metadata.metadata.where().findAll())
              .map((m) => _metadata.metadata.delete(m.id)),
        ),
      );

  /// Remove all the key-value pairs from the store
  ///
  /// Prefer [resetAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  void reset() => _metadata.writeTxnSync(
        () => Future.wait(
          _metadata.metadata
              .where()
              .findAllSync()
              .map((m) => _metadata.metadata.delete(m.id)),
        ),
      );

  /// Read all the key-value pairs from the store
  Future<Map<String, String>> get readAsync async => Map.fromEntries(
        (await _metadata.metadata.where().findAll())
            .map((m) => MapEntry(m.name, m.data)),
      );

  /// Read all the key-value pairs from the store
  ///
  /// Prefer [readAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  Map<String, String> get read => Map.fromEntries(
        _metadata.metadata
            .where()
            .findAllSync()
            .map((m) => MapEntry(m.name, m.data)),
      );
}
