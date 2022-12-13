// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../fmtc.dart';

/// Manages a [StoreDirectory]'s representation on the filesystem, such as
/// creation and deletion
@internal
class StoreManagement {
  StoreManagement._(this._storeDirectory);
  final StoreDirectory _storeDirectory;

  FMTCRegistry get _registry => FMTCRegistry.instance;

  /// Create all of the directories asynchronously
  Future<void> create() async {
    await _registry.registryDatabase.writeTxn(
      () => _registry.registryDatabase.stores
          .put(DbStore(name: _storeDirectory.storeName)),
    );
    await _registry.synchronise();
  }

  /// Create all of the directories asynchronously
  ///
  /// Advanced version of [create] intended for internal usage in certain
  /// circumstances only.
  Future<int> _advancedCreate({bool synchronise = true}) async {
    final id = await _registry.registryDatabase.writeTxn(
      () => _registry.registryDatabase.stores
          .put(DbStore(name: _storeDirectory.storeName)),
    );
    if (synchronise) await _registry.synchronise();
    return id;
  }

  /// Delete all of the directories asynchronously
  ///
  /// This will remove all traces of this store from the user's device. Use with
  /// caution!
  Future<void> delete() async {
    await _registry.registryDatabase.writeTxn(
      () => _registry.registryDatabase.stores
          .delete(DatabaseTools.hash(_storeDirectory.storeName)),
    );
    await _registry.synchronise();
  }

  /// Resets this store asynchronously
  ///
  /// This will remove all traces of this store from the user's device. Use with
  /// caution!
  Future<void> reset() async {
    await create();
    await delete();
  }

  /// Rename the store directory asynchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so
  /// always use the new returned value instead: returns a new [StoreDirectory]
  /// after a successful renaming operation.
  Future<StoreDirectory> rename(String storeName) async {
    File constructor(String name) =>
        FMTC.instance.rootDirectory.directory >>>
        '${DatabaseTools.hash(name)}.isar';

    // Close the currently opened store
    await _registry
        .tileDatabases[DatabaseTools.hash(_storeDirectory.storeName)]!
        .close();
    await _registry.registryDatabase.writeTxn(() async {
      // Register a new store in the registry and unregister the old one
      await _registry.registryDatabase.stores
          .delete(DatabaseTools.hash(_storeDirectory.storeName));
      await _registry.registryDatabase.stores.put(DbStore(name: storeName));
      // Manually rename the old file (with the old ID) to the new ID
      await constructor(_storeDirectory.storeName)
          .rename(constructor(storeName).absolute.path);
    });
    await _registry.synchronise();

    return _storeDirectory.copyWith(storeName: storeName);
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
  /*Image? tileImage({
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
  }*/
}
