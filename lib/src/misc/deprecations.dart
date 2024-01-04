// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

// TODO: Store management deprecations

const _syncRemoval = '''

Synchronous operations have been removed throughout FMTC v9, therefore the distinction between sync and async operations has been removed.
This deprecated member will be removed in a future version.
''';

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

/// Provides deprecations where possible for previous methods in [StoreStats]
/// after the v9 release.
///
/// Synchronous operations have been removed throughout FMTC v9, therefore the
/// distinction between sync and async operations has been removed.
///
/// Provided in an extension method for easy differentiation and quick removal.
@Deprecated(
  '''
Migrate to the suggested replacements for each operation.
Synchronous operations have been removed throughout FMTC v9, therefore the distinction between sync and async operations has been removed. 
This deprecated member will be removed in a future version.
''',
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
}
