// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages a [StoreDirectory]'s representation on the filesystem, such as
/// creation and deletion
///
/// If the store is not in the expected state (of existence) when invoking an
/// operation, then an error will be thrown (likely [StoreNotExists] or
/// [StoreAlreadyExists]). It is recommended to check [ready] or [readySync] when
/// necessary.
final class StoreManagement extends _WithBackendAccess {
  StoreManagement._(super.store);

  /// Whether this store exists
  Future<bool> get ready => _backend.storeExists(storeName: _storeName);

  /// Whether this store exists
  bool get readySync => _backend.storeExistsSync(storeName: _storeName);

  /// Create this store
  Future<void> create() => _backend.createStore(storeName: _storeName);

  /// Create this store
  void createSync() => _backend.createStoreSync(storeName: _storeName);

  /// Delete this store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
  Future<void> delete() => _backend.deleteStore(storeName: _storeName);

  /// Delete this store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
  void deleteSync() => _backend.deleteStoreSync(storeName: _storeName);

  /// Removes all tiles from this store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
  Future<void> reset() => _backend.resetStore(storeName: _storeName);

  /// Removes all tiles from this store
  ///
  /// This operation cannot be undone! Ensure you confirm with the user that
  /// this action is expected.
  void resetSync() => _backend.resetStoreSync(storeName: _storeName);

  /// Rename the store directory
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so
  /// always use the new returned value instead: returns a new [StoreDirectory]
  /// after a successful renaming operation.
  ///
  /// This method requires the store to be [ready], else an [FMTCStoreNotReady]
  /// error will be raised.
  Future<StoreDirectory> rename(String newStoreName) async {
    await _backend.renameStore(
      currentStoreName: _storeName,
      newStoreName: newStoreName,
    );

    // TODO: `autoCreate` and entire shortcut will now be broken by default
    // consider whether this bi-synchronousable approach is sustainable
    return StoreDirectory._(newStoreName, autoCreate: false);
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
