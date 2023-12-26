// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages a [StoreDirectory]'s representation on the filesystem, such as
/// creation and deletion
final class StoreManagement extends _WithBackendAccess {
  StoreManagement._(super.store)
      : _rootDirectory = FMTC.instance.rootDirectory.directory;

  final Directory _rootDirectory;

  /// Check whether this store is ready for use
  ///
  /// It must be registered, and its underlying database must be open, for this
  /// method to return `true`.
  ///
  /// This is a safe method, and will not throw the [FMTCStoreNotReady] error,
  /// except in exceptional circumstances.
  bool get ready {
    try {
      _registry(_name);
      return true;
      // ignore: avoid_catching_errors
    } on FMTCStoreNotReady catch (e) {
      if (e.registered) rethrow;
      return false;
    }
  }

  /// Create this store asynchronously
  ///
  /// Does nothing if the store already exists.
  Future<void> createAsync() async {
    if (ready) return;

    final db = await Isar.open(
      [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
      name: _id.toString(),
      directory: _rootDirectory.path,
      maxSizeMiB: FMTC.instance.settings.databaseMaxSize,
      compactOnLaunch: FMTC.instance.settings.databaseCompactCondition,
      inspector: false,
    );
    await db.writeTxn(
      () => db.storeDescriptor.put(DbStoreDescriptor(name: _name)),
    );
    _registry.register(_id, db);
  }

  /// Create this store synchronously
  ///
  /// Prefer [createAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  ///
  /// Does nothing if the store already exists.
  void create() {
    if (ready) return;

    final db = Isar.openSync(
      [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
      name: _id.toString(),
      directory: _rootDirectory.path,
      maxSizeMiB: FMTC.instance.settings.databaseMaxSize,
      compactOnLaunch: FMTC.instance.settings.databaseCompactCondition,
      inspector: false,
    );
    db.writeTxnSync(
      () => db.storeDescriptor.putSync(DbStoreDescriptor(name: _name)),
    );
    _registry.register(_id, db);
  }

  /// Delete this store
  ///
  /// This will remove all traces of this store from the user's device. Use with
  /// caution!
  ///
  /// Does nothing if the store does not already exist.
  Future<void> delete() async {
    if (!ready) return;

    final store = _registry.unregister(_id);
    if (store?.isOpen ?? false) await store!.close(deleteFromDisk: true);
  }

  /// Removes all tiles from this store synchronously
  ///
  /// Also resets the cache hits & misses statistic.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  Future<void> resetAsync() async {
    final db = _registry(_name);
    await db.writeTxn(() async {
      await db.tiles.clear();
      await db.storeDescriptor.put(
        (await db.descriptor)
          ..hits = 0
          ..misses = 0,
      );
    });
  }

  /// Removes all tiles from this store asynchronously
  ///
  /// Also resets the cache hits & misses statistic.
  ///
  /// Prefer [resetAsync] to avoid blocking the UI thread. Otherwise, this has
  /// slightly better performance.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  void reset() {
    final db = _registry(_name);
    db.writeTxnSync(() {
      db.tiles.clearSync();
      db.storeDescriptor.putSync(
        db.descriptorSync
          ..hits = 0
          ..misses = 0,
      );
    });
  }

  /// Rename the store directory asynchronously
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so
  /// always use the new returned value instead: returns a new [StoreDirectory]
  /// after a successful renaming operation.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  Future<StoreDirectory> rename(String newStoreName) async {
    // Unregister and close old database without deleting it
    final store = _registry.unregister(_id);
    if (store == null) {
      _registry(_name);
      throw StateError(
        'This error represents a serious internal error in FMTC. Please raise a bug report if seen in any application',
      );
    }
    await store.close();

    // Manually change the database's filename
    await (_rootDirectory >>> '$_id.isar').rename(
      (_rootDirectory >>> '${DatabaseTools.hash(newStoreName)}.isar').path,
    );

    // Register the new database (it will be re-opened)
    final newStore = StoreDirectory._(newStoreName, autoCreate: false);
    await newStore.manage.createAsync();

    // Update the name stored inside the database
    await _registry(newStoreName).writeTxn(
      () => _registry(newStoreName)
          .storeDescriptor
          .put(DbStoreDescriptor(name: newStoreName)),
    );

    return newStore;
  }

  /// Delete all tiles older that were last modified before [expiry]
  ///
  /// Ignores [FMTCTileProviderSettings.cachedValidDuration].
  Future<void> pruneTilesOlderThan({required DateTime expiry}) => compute(
        _pruneTilesOlderThanWorker,
        [_name, _rootDirectory.absolute.path, expiry],
      );

  /// Retrieves the most recently modified tile from the store, extracts it's
  /// bytes, and renders them to an [Image]
  ///
  /// Prefer [tileImageAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  ///
  /// Eventually returns `null` if there are no cached tiles in this store,
  /// otherwise an [Image] with [size] height and width.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  Image? tileImage({
    double? size,
    Key? key,
    double scale = 1.0,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final latestTile = _registry(_name)
        .tiles
        .where(sort: Sort.desc)
        .anyLastModified()
        .limit(1)
        .findFirstSync();
    if (latestTile == null) return null;

    return Image.memory(
      Uint8List.fromList(latestTile.bytes),
      key: key,
      scale: scale,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: size,
      height: size,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  /// Retrieves the most recently modified tile from the store, extracts it's
  /// bytes, and renders them to an [Image]
  ///
  /// Eventually returns `null` if there are no cached tiles in this store,
  /// otherwise an [Image] with [size] height and width.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  ///
  Future<Image?> tileImageAsync({
    double? size,
    Key? key,
    double scale = 1.0,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) async {
    final latestTile = await _registry(_name)
        .tiles
        .where(sort: Sort.desc)
        .anyLastModified()
        .limit(1)
        .findFirst();
    if (latestTile == null) return null;

    return Image.memory(
      Uint8List.fromList(latestTile.bytes),
      key: key,
      scale: scale,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: size,
      height: size,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

Future<void> _pruneTilesOlderThanWorker(List<dynamic> args) async {
  final db = Isar.openSync(
    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
    name: DatabaseTools.hash(args[0]).toString(),
    directory: args[1],
    inspector: false,
  );

  db.writeTxnSync(
    () => db.tiles.deleteAllSync(
      db.tiles
          .where()
          .lastModifiedLessThan(args[2])
          .findAllSync()
          .map((t) => t.id)
          .toList(),
    ),
  );

  await db.close();
}
