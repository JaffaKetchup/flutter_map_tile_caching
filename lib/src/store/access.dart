// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import '../internal/exts.dart';
import '../internal/filesystem_sanitiser_private.dart';
import 'directory.dart';

/// Provides direct filesystem access paths to a [StoreDirectory] - use with caution
class StoreAccess {
  /// The store directory to provide access paths to
  final StoreDirectory _storeDirectory;

  /// Provides direct filesystem access paths to a [StoreDirectory] - use with caution
  StoreAccess(this._storeDirectory) {
    real = _storeDirectory.rootDirectory.access.stores >>
        filesystemSanitiseValidate(
          inputString: _storeDirectory.storeName,
          throwIfInvalid: true,
        );

    tiles = real >> 'tiles';
    stats = real >> 'stats';
    metadata = real >> 'metadata';
  }

  /// The real parent [Directory] of the [StoreDirectory] - directory name is equal to store's name
  late final Directory real;

  /// The sub[Directory] used to store map tiles
  late final Directory tiles;

  /// The sub[Directory] used to store cached statistics
  late final Directory stats;

  /// The sub[Directory] used to store any miscellaneous metadata
  late final Directory metadata;
}
