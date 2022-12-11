// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE
/*
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import '../db/defs/store.dart';
import '../db/defs/tile.dart';
import '../fmtc.dart';
import '../internal/exts.dart';
import '../internal/filesystem_sanitiser_private.dart';
import 'access.dart';
import 'directory.dart';
import 'metadata.dart';
import 'statistics.dart';

/// Manages a [StoreDirectory]'s representation on the filesystem, such as creation and deletion
class StoreManagement {
  /// The store directory to manage
  final StoreDirectory _storeDirectory;

  String get _storeName => _storeDirectory.storeName;
  Directory get _rootDirectory => FMTC.instance.rootDirectory.rootDirectory;
  Map<String, Isar> get _databases => FMTC.instance.databases;

  /// Manages a [StoreDirectory]'s representation on the filesystem, such as creation and deletion
  StoreManagement(this._storeDirectory);

  /// Check whether all directories exist asynchronously
  Future<bool> get readyAsync async => (await Future.wait<bool>([
        _access.tiles.exists(),
        _access.stats.exists(),
        _access.metadata.exists(),
      ]))
          .every((e) => e);

  /// Create all of the directories asynchronously
  Future<void> createAsync() async {
    _databases[_storeName] = await Isar.open(
      [TileSchema],
      name: _storeName,
      directory: _rootDirectory.absolute.path,
    );
    await _databases['']!
        .writeTxn(() => _databases['']!.stores.put(Store(name: _storeName)));
  }

  /// Delete all of the directories asynchronously
  ///
  /// This will remove all traces of this store from the user's device. Use with caution!
  Future<void> deleteAsync() async {
    await resetAsync();
    await _access.real.delete(recursive: true);
  }

  /// Resets this store synchronously
  ///
  /// Deletes all files within the [StoreAccess.tiles] directory, and invalidates any cached statistics ([StoreStats.invalidateCachedStatisticsAsync]). Therefore, custom metadata ([StoreMetadata]) is not deleted.
  ///
  /// For a full reset, manually [deleteAsync] then [createAsync] the store.
  Future<void> resetAsync() async {
    await Future.wait(
      await (await _access.tiles.listWithExists())
          .map((e) => e.delete())
          .toList(),
    );
    await _storeDirectory.stats
        .invalidateCachedStatisticsAsync(statTypes: null);
  }

  /// Rename the store directory synchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  StoreDirectory rename(String storeName) {
    final String safe = filesystemSanitiseValidate(
      inputString: storeName,
      throwIfInvalid: true,
    );

    if (safe != _storeDirectory.storeName) {
      _access.real.renameSync(
        p.joinAll([_storeDirectory.rootDirectory.access.real.path, safe]),
      );
    }

    return _storeDirectory.copyWith(storeName: safe);
  }

  /// Rename the store directory asynchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so always use the new returned value instead: returns a new [StoreDirectory] after a successful renaming operation.
  Future<StoreDirectory> renameAsync(String storeName) async {
    final String safe = filesystemSanitiseValidate(
      inputString: storeName,
      throwIfInvalid: true,
    );

    if (safe != _storeDirectory.storeName) {
      await _access.real.rename(
        p.joinAll([_storeDirectory.rootDirectory.access.stores.path, safe]),
      );
    }

    return _storeDirectory.copyWith(storeName: safe);
  }

  /// Retrieves a tile from the store and extracts it's [Image] synchronously
  ///
  /// [randomRange] controls the randomness of the tile chosen (defaults to `null`):
  /// * null                  : no randomness - the first tile is chosen
  /// * value <= 0            : any tile may be chosen
  /// * value >= store length : any tile may be chosen
  /// * value < store length  : any tile up to this range may be chosen, enforcing an iteration limit internally
  ///
  /// Note that tiles are not necessarily ordered chronologically. They are usually ordered alphabetically.
  ///
  /// Returns `null` if there are no cached tiles in this store, otherwise an [Image] with [size] height and width.
  Image? tileImage({
    int? randomRange,
    double? size,
  }) {
    final int storeLen = _storeDirectory.stats.storeLength;
    if (storeLen == 0) return null;

    int i = 0;

    final int randomNumber = randomRange == null
        ? 0
        : Random().nextInt(
            randomRange <= 0 ? storeLen : randomRange.clamp(0, storeLen),
          );

    for (final FileSystemEntity e in _access.tiles.listSync()) {
      if (i >= randomNumber) {
        return Image.file(
          File(e.absolute.path),
          width: size,
          height: size,
        );
      }
      i++;
    }

    return null;
  }

  /// Retrieves a tile from the store and extracts it's [Image] asynchronously
  ///
  /// [randomRange] controls the randomness of the tile chosen (defaults to `null`):
  /// * null                  : no randomness - the first tile is chosen
  /// * value <= 0            : any tile may be chosen
  /// * value >= store length : any tile may be chosen
  /// * value < store length  : any tile up to this range may be chosen, enforcing an iteration limit internally
  ///
  /// Note that tiles are not necessarily ordered chronologically. They are usually ordered alphabetically.
  ///
  /// Eventually returns `null` if there are no cached tiles in this store, otherwise an [Image] with [size] height and width.
  Future<Image?> tileImageAsync({
    int? randomRange,
    double? size,
  }) async {
    final int storeLen = await _storeDirectory.stats.storeLengthAsync;
    if (storeLen == 0) return null;

    int i = 0;

    final int randomNumber = randomRange == null
        ? 0
        : Random().nextInt(
            randomRange <= 0 ? storeLen : randomRange.clamp(0, storeLen),
          );

    await for (final FileSystemEntity e
        in await _access.tiles.listWithExists()) {
      if (i >= randomNumber) {
        return Image.file(
          File(e.absolute.path),
          width: size,
          height: size,
        );
      }
      i++;
    }

    return null;
  }
}
*/