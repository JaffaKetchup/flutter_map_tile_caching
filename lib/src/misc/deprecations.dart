// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

const _syncRemoval = '''

Synchronous operations have been removed throughout FMTC v9, therefore the distinction between sync and async operations has been removed.
This deprecated member will be removed in a future version.
''';

//! ROOT !//

/// Provides deprecations where possible for previous methods in [RootStats]
/// after the v9 release.
///
/// Synchronous operations have been removed throughout FMTC v9, therefore the
/// distinction between sync and async operations has been removed.
///
/// Provided in an extension method for easy differentiation and quick removal.
@Deprecated(
  'Migrate to the suggested replacements for each operation. $_syncRemoval',
)
extension RootStatsDeprecations on RootStats {
  /// {@macro fmtc.backend.listStores}
  @Deprecated('Migrate to `storesAvailable`. $_syncRemoval')
  Future<List<StoreDirectory>> get storesAvailableAsync => storesAvailable;

  /// {@macro fmtc.backend.rootSize}
  @Deprecated('Migrate to `size`. $_syncRemoval')
  Future<double> get rootSizeAsync => size;

  /// {@macro fmtc.backend.rootLength}
  @Deprecated('Migrate to `length`. $_syncRemoval')
  Future<int> get rootLengthAsync => length;
}

/// Provides deprecations where possible for previous methods in [RootRecovery]
/// after the v9 release.
///
/// Synchronous operations have been removed throughout FMTC v9, therefore the
/// distinction between sync and async operations has been removed.
///
/// Provided in an extension method for easy differentiation and quick removal.
@Deprecated(
  'Migrate to the suggested replacements for each operation. $_syncRemoval',
)
extension RootRecoveryDeprecations on RootRecovery {
  /// List all failed failed downloads
  ///
  /// {@macro fmtc.rootRecovery.failedDefinition}
  @Deprecated('Migrate to `recoverableRegions.failedOnly`. $_syncRemoval')
  Future<List<RecoveredRegion>> get failedRegions =>
      recoverableRegions.then((e) => e.failedOnly.toList());
}

//! STORE !//

/// Provides deprecations where possible for previous methods in
/// [StoreManagement] after the v9 release.
///
/// Synchronous operations have been removed throughout FMTC v9, therefore the
/// distinction between sync and async operations has been removed.
///
/// Provided in an extension method for easy differentiation and quick removal.
@Deprecated(
  'Migrate to the suggested replacements for each operation. $_syncRemoval',
)
extension StoreManagementDeprecations on StoreManagement {
  /// {@macro fmtc.backend.createStore}
  @Deprecated('Migrate to `create`. $_syncRemoval')
  Future<void> createAsync() => create();

  /// {@macro fmtc.backend.resetStore}
  @Deprecated('Migrate to `reset`. $_syncRemoval')
  Future<void> resetAsync() => reset();

  /// {@macro fmtc.backend.deleteStore}
  @Deprecated('Migrate to `delete`. $_syncRemoval')
  Future<void> deleteAsync() => delete();

  /// {@macro fmtc.backend.renameStore}
  @Deprecated('Migrate to `rename`. $_syncRemoval')
  Future<FMTCStore> renameAsync(String newStoreName) => rename(newStoreName);
}

/// Provides deprecations where possible for previous methods in [StoreStats]
/// after the v9 release.
///
/// Synchronous operations have been removed throughout FMTC v9, therefore the
/// distinction between sync and async operations has been removed.
///
/// Provided in an extension method for easy differentiation and quick removal.
@Deprecated(
  'Migrate to the suggested replacements for each operation. $_syncRemoval',
)
extension StoreStatsDeprecations on StoreStats {
  /// Retrieve the total number of KiBs of all tiles' bytes (not 'real total'
  /// size)
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  @Deprecated('Migrate to `size`. $_syncRemoval')
  Future<double> get storeSizeAsync => size;

  /// Retrieve the number of tiles belonging to this store
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  @Deprecated('Migrate to `length`. $_syncRemoval')
  Future<int> get storeLengthAsync => length;

  /// Retrieve the number of successful tile retrievals when browsing
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  @Deprecated('Migrate to `hits`.$_syncRemoval')
  Future<int> get cacheHitsAsync => hits;

  /// Retrieve the number of unsuccessful tile retrievals when browsing
  ///
  /// {@macro fmtc.frontend.storestats.efficiency}
  @Deprecated('Migrate to `misses`. $_syncRemoval')
  Future<int> get cacheMissesAsync => misses;

  /// {@macro fmtc.backend.tileImage}
  /// , then render the bytes to an [Image]
  @Deprecated('Migrate to `tileImage`. $_syncRemoval')
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
  }) =>
      tileImage(
        size: size,
        key: key,
        scale: scale,
        frameBuilder: frameBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
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

/// Provides deprecations where possible for previous methods in [StoreMetadata]
/// after the v9 release.
///
/// Synchronous operations have been removed throughout FMTC v9, therefore the
/// distinction between sync and async operations has been removed.
///
/// Provided in an extension method for easy differentiation and quick removal.
@Deprecated(
  'Migrate to the suggested replacements for each operation. $_syncRemoval',
)
extension StoreMetadataDeprecations on StoreMetadata {
  /// {@macro fmtc.backend.readMetadata}
  @Deprecated('Migrate to `read`. $_syncRemoval')
  Future<Map<String, String>> get readAsync => read;

  /// {@macro fmtc.backend.setMetadata}
  @Deprecated('Migrate to `set`. $_syncRemoval')
  Future<void> addAsync({required String key, required String value}) =>
      set(key: key, value: value);

  /// {@macro fmtc.backend.removeMetadata}
  @Deprecated('Migrate to `remove`.$_syncRemoval')
  Future<void> removeAsync({required String key}) => remove(key: key);

  /// {@macro fmtc.backend.resetMetadata}
  @Deprecated('Migrate to `reset`. $_syncRemoval')
  Future<void> resetAsync() => reset();
}
