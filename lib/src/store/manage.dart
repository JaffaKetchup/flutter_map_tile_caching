// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Manages a [StoreDirectory]'s representation on the filesystem, such as
/// creation and deletion
class StoreManagement {
  StoreManagement._(this._storeDirectory)
      : _id = DatabaseTools.hash(_storeDirectory.storeName),
        _registry = FMTCRegistry.instance,
        _rootDirectory = FMTC.instance.rootDirectory.directory;

  final StoreDirectory _storeDirectory;
  final int _id;
  final FMTCRegistry _registry;
  final Directory _rootDirectory;

  void _ensureReadyStatus() {
    final isRegistered = _registry.storeDatabases.containsKey(_id);
    if (isRegistered && _registry.storeDatabases[_id]!.isOpen) return;
    throw FMTCStoreNotReady._(
      storeName: _storeDirectory.storeName,
      registered: isRegistered,
    );
  }

  /// Check whether this store is ready for use
  ///
  /// It must be registered, and its underlying database must be open for this
  /// method to return `true`.
  ///
  /// This is a safe method, and will not throw the [FMTCStoreNotReady] error,
  /// except in exceptional circumstances.
  bool get ready {
    try {
      _ensureReadyStatus();
      return true;
      // ignore: avoid_catching_errors
    } on FMTCStoreNotReady catch (e) {
      if (e._registered) rethrow;
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
    );
    await db.writeTxn(
      () => db.storeDescriptor
          .put(DbStoreDescriptor(name: _storeDirectory.storeName)),
    );
    _registry.storeDatabases[_id] = db;
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
    );
    db.writeTxnSync(
      () => db.storeDescriptor
          .putSync(DbStoreDescriptor(name: _storeDirectory.storeName)),
    );
    _registry.storeDatabases[_id] = db;
  }

  Future<int?> _advancedCreate() async {
    if (ready) return null;

    final db = await Isar.open(
      [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
      name: _id.toString(),
      directory: _rootDirectory.path,
      maxSizeMiB: FMTC.instance.settings.databaseMaxSize,
      compactOnLaunch: FMTC.instance.settings.databaseCompactCondition,
    );
    await db.writeTxn(
      () => db.storeDescriptor
          .put(DbStoreDescriptor(name: _storeDirectory.storeName)),
    );
    _registry.storeDatabases[_id] = db;
    return _id;
  }

  /// Delete this store
  ///
  /// This will remove all traces of this store from the user's device. Use with
  /// caution!
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  Future<void> delete() async {
    _ensureReadyStatus();

    final store = _registry.storeDatabases.remove(_id);
    if (store?.isOpen ?? false) await store!.close(deleteFromDisk: true);
  }

  /// Removes all tiles from this store synchronously
  ///
  /// Also resets the cache hits & misses statistic.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  Future<void> resetAsync() async {
    _ensureReadyStatus();

    final db = _registry.storeDatabases[_id]!;
    await db.writeTxn(() async {
      await db.tiles.clear();
      await db.storeDescriptor.put(
        (await db.storeDescriptor.get(0))!
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
    _ensureReadyStatus();

    final db = _registry.storeDatabases[_id]!;
    db.writeTxnSync(() {
      db.tiles.clearSync();
      db.storeDescriptor.putSync(
        db.storeDescriptor.getSync(0)!
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
    _ensureReadyStatus();

    // Unregister old database without deleting it
    final oldStore = _registry.storeDatabases.remove(_id);
    if (oldStore!.isOpen) await oldStore.close();

    final newId = DatabaseTools.hash(newStoreName);

    // Manually change the database's filename
    await (_rootDirectory >>> '$_id.isar').rename(
      (_rootDirectory >>> '$newId.isar').path,
    );

    // Register the new database (it will be re-opened)
    final newStore = StoreDirectory._(newStoreName);
    await newStore.manage.createAsync();

    // Update the name stored inside the database
    await _registry.storeDatabases[newId]?.writeTxn(
      () => _registry.storeDatabases[newId]!.storeDescriptor
          .put(DbStoreDescriptor(name: newStoreName)),
    );

    return newStore;
  }

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
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
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
    _ensureReadyStatus();

    final latestTile = _registry
        .storeDatabases[DatabaseTools.hash(_storeDirectory.storeName)]!.tiles
        .where(sort: Sort.desc)
        .anyLastModified()
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
  Future<Image?> tileImageAsync({
    double? size,
    Key? key,
    double scale = 1.0,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
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
    _ensureReadyStatus();

    final latestTile = await _registry
        .storeDatabases[DatabaseTools.hash(_storeDirectory.storeName)]!.tiles
        .where(sort: Sort.desc)
        .anyLastModified()
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

  //! DEPRECATED METHODS !//

  /// 'readyAsync' is deprecated and shouldn't be used. Prefer [ready]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'ready'. This redirect will be removed in a future update",
  )
  Future<bool> get readyAsync => Future.sync(() => ready);

  /// 'deleteAsync' is deprecated and shouldn't be used. Prefer [delete]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'delete'. This redirect will be removed in a future update",
  )
  Future<void> deleteAsync() => delete();

  /// 'renameAsync' is deprecated and shouldn't be used. Prefer [rename]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'rename'. This redirect will be removed in a future update",
  )
  Future<StoreDirectory?> renameAsync(String storeName) => rename(storeName);
}

/// An error rasied by multiple methods that require the existence of the
/// requested store
class FMTCStoreNotReady extends Error {
  /// The store name that the method tried to access
  final String storeName;

  /// A human readable description of the error, and steps that may be taken to
  /// avoid this error being thrown again
  final String message;

  final bool _registered;

  FMTCStoreNotReady._({
    required this.storeName,
    required bool registered,
  })  : _registered = registered,
        message = registered
            ? "The store ('$storeName') was registered, but the underlying database was not open, at this time. This is an erroneous state in FMTC: if this error appears in your application, please open an issue on GitHub immediately."
            : "The store ('$storeName') does not exist at this time, and is not ready. Ensure that your application does not use the method that triggered this error unless it is sure that the store will exist at this point.";

  /// Similar to [message], but suitable for console output in an unknown context
  @override
  String toString() => 'FMTCStoreNotReady: $message';
}
