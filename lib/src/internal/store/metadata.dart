import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';

import '../exts.dart';
import 'access.dart';
import 'directory.dart';

/// Manage custom miscellaneous information tied to a [StoreDirectory]
///
/// Uses a key-value format where both key and value must be [String]. There is no validation or sanitisation on any keys or values; note that keys form part of filenames.
///
/// Also used internally to store bulk download recovery files ending in '.recovery.ini'.
class StoreMetadata {
  /// The file extension for all custom metadata files
  static const _metadataExtension = '.metadata';

  /// Manage custom miscellaneous information tied to a [StoreDirectory]
  ///
  /// Uses a key-value format where both key and value must be [String]. There is no validation or sanitisation on any keys or values; note that keys form part of filenames.
  ///
  /// Also used internally to store bulk download recovery files ending in '.recovery.ini'.
  StoreMetadata(StoreDirectory storeDirectory)
      : _access = StoreAccess(storeDirectory).metadata;

  /// Shorthand for [StoreAccess.metadata], used commonly throughout
  final Directory _access;

  /// Add a new key-value pair to the store asynchronously
  ///
  /// Overwrites the value if the key already exists.
  Future<void> addAsync({
    required String key,
    required String value,
  }) async {
    final File file = _access >>> key + _metadataExtension;
    await file.create();
    await file.writeAsString(value);
  }

  /// Add a new key-value pair to the store synchronously
  ///
  /// Overwrites the value if the key already exists.
  void add({
    required String key,
    required String value,
  }) =>
      (_access >>> key + _metadataExtension)
        ..createSync()
        ..writeAsStringSync(value);

  /// Remove a new key-value pair from the store asynchronously
  Future<void> removeAsync({required String key}) async {
    final File file = _access >>> key + _metadataExtension;
    if (await file.exists()) await file.delete();
  }

  /// Remove a new key-value pair from the store synchronously
  void remove({required String key}) {
    final File file = _access >>> key + _metadataExtension;
    if (file.existsSync()) file.deleteSync();
  }

  /// Remove all the key-value pairs from the store asynchronously
  Future<void> resetAsync() async {
    for (final File f in await _access
        .list()
        .map(
          (e) => p.extension(e.absolute.path) == _metadataExtension ? e : null,
        )
        .whereType<File>()
        .toList()) {
      await f.delete();
    }
  }

  /// Remove all the key-value pairs from the store synchronously
  void reset() {
    for (final File f in _access
        .listSync()
        .map(
          (e) => p.extension(e.absolute.path) == _metadataExtension ? e : null,
        )
        .whereType<File>()
        .toList()) {
      f.deleteSync();
    }
  }

  Future<Map<String, String>> get readAsync async => (await _access
              .list()
              .asyncMap(
                (e) async =>
                    e is File && p.extension(e.absolute.path) == '.metadata'
                        ? {
                            p.basenameWithoutExtension(e.absolute.path):
                                await e.readAsString()
                          }
                        : null,
              )
              .whereType<Map<String, String>>()
              .toList())
          .reduce((v, e) {
        v.addAll(e);
        return v;
      });

  Map<String, String> get read => _access
          .listSync()
          .map(
            (e) => e is File
                ? {
                    p.basenameWithoutExtension(e.absolute.path):
                        e.readAsStringSync()
                  }
                : null,
          )
          .whereType<Map<String, String>>()
          .reduce((v, e) {
        v.addAll(e);
        return v;
      });
}
