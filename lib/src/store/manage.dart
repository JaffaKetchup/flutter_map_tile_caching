// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages a [StoreDirectory]'s representation on the filesystem, such as
/// creation and deletion
///
/// If the store is not in the expected state (of existence) when invoking an
/// operation, then an error will be thrown (likely [StoreNotExists] or
/// [StoreAlreadyExists]). It is recommended to check [ready] when necessary.
final class StoreManagement extends _WithBackendAccess {
  const StoreManagement._(super.store);

  /// {@macro fmtc.backend.storeExists}
  Future<bool> get ready => _backend.storeExists(storeName: _storeName);

  /// {@macro fmtc.backend.createStore}
  Future<void> create() => _backend.createStore(storeName: _storeName);

  /// {@macro fmtc.backend.deleteStore}
  Future<void> delete() => _backend.deleteStore(storeName: _storeName);

  /// {@macro fmtc.backend.resetStore}
  Future<void> reset() => _backend.resetStore(storeName: _storeName);

  /// {@macro fmtc.backend.renameStore}
  ///
  /// The old [StoreDirectory] will still retain it's link to the old store, so
  /// always use the new returned value instead: returns a new [StoreDirectory]
  /// after a successful renaming operation.
  Future<StoreDirectory> rename(String newStoreName) async {
    await _backend.renameStore(
      currentStoreName: _storeName,
      newStoreName: newStoreName,
    );

    return StoreDirectory._(newStoreName);
  }

  /// {@macro fmtc.backend.removeTilesOlderThan}
  Future<void> removeTilesOlderThan({required DateTime expiry}) =>
      _backend.removeTilesOlderThan(storeName: _storeName, expiry: expiry);

  /// {@macro fmtc.backend.readLatestTile}
  /// , then render the bytes to an [Image]
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
    final latestTile = await _backend.readLatestTile(storeName: _storeName);
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
