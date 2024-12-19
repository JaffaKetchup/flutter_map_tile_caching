// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Provides statistics about a [FMTCRoot]
class RootStats {
  const RootStats._();

  /// {@macro fmtc.backend.listStores}
  Future<List<FMTCStore>> get storesAvailable => FMTCBackendAccess.internal
      .listStores()
      .then((s) => s.map(FMTCStore.new).toList());

  /// {@macro fmtc.backend.realSize}
  Future<double> get realSize => FMTCBackendAccess.internal.realSize();

  /// {@macro fmtc.backend.rootSize}
  Future<double> get size => FMTCBackendAccess.internal.rootSize();

  /// {@macro fmtc.backend.rootLength}
  Future<int> get length => FMTCBackendAccess.internal.rootLength();

  /// {@macro fmtc.backend.watchRecovery}
  @Deprecated('This has been moved to `FMTCRoot.recovery` & renamed `.watch`')
  Stream<void> watchRecovery({
    bool triggerImmediately = false,
  }) =>
      FMTCRoot.recovery.watch(triggerImmediately: triggerImmediately);

  /// {@macro fmtc.backend.watchStores}
  ///
  /// If [storeNames] is empty, changes will be watched in all stores.
  Stream<void> watchStores({
    List<String> storeNames = const [],
    bool triggerImmediately = false,
  }) async* {
    final stream = FMTCBackendAccess.internal.watchStores(
      storeNames: storeNames,
      triggerImmediately: triggerImmediately,
    );
    yield* stream;
  }
}
