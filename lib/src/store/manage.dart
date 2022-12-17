// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Manages a [StoreDirectory]'s representation on the filesystem, such as
/// creation and deletion
class StoreManagement {
  StoreManagement._(this._storeDirectory);
  final StoreDirectory _storeDirectory;

  FMTCRegistry get _registry => FMTCRegistry.instance;

  /// Check whether this store is ready for use
  Future<bool> get ready async {
    await _registry.synchronise();
    return await _registry.registryDatabase.stores
            .get(DatabaseTools.hash(_storeDirectory.storeName)) !=
        null;
  }

  /// Create this store
  Future<void> create() async {
    await _registry.registryDatabase.writeTxn(
      () => _registry.registryDatabase.stores
          .put(DbStore(name: _storeDirectory.storeName)),
    );
    await _registry.synchronise();
  }

  /// Create this store
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

  /// Delete this store
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

  /// Resets this store (deletes then creates)
  ///
  /// This will remove all traces of this store from the user's device. Use with
  /// caution!
  Future<void> reset() async {
    await delete();
    await create();
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

    return _storeDirectory.copyWith(storeName);
  }

  /// Retrieves the most recently modified tile from the store, extracts it's
  /// bytes, and renders them to an [Image]
  ///
  /// Prefer [tileImageAsync] to avoid blocking the UI thread. Otherwise, this
  /// has slightly better performance.
  ///
  /// Eventually returns `null` if there are no cached tiles in this store,
  /// otherwise an [Image] with [size] height and width.
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
    final latestTile = _registry
        .tileDatabases[DatabaseTools.hash(_storeDirectory.storeName)]!.tiles
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
    final latestTile = await _registry
        .tileDatabases[DatabaseTools.hash(_storeDirectory.storeName)]!.tiles
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
  Future<bool> get readyAsync => ready;

  /// 'createAsync' is deprecated and shouldn't be used. Prefer [create]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'create'. This redirect will be removed in a future update",
  )
  Future<void> createAsync() => create();

  /// 'deleteAsync' is deprecated and shouldn't be used. Prefer [delete]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'delete'. This redirect will be removed in a future update",
  )
  Future<void> deleteAsync() => delete();

  /// 'resetAsync' is deprecated and shouldn't be used. Prefer [reset]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'reset'. This redirect will be removed in a future update",
  )
  Future<void> resetAsync() => reset();

  /// 'renameAsync' is deprecated and shouldn't be used. Prefer [rename]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'rename'. This redirect will be removed in a future update",
  )
  Future<StoreDirectory> renameAsync(String storeName) => rename(storeName);
}
