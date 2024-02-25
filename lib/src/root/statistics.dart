// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Provides statistics about a [FMTCRoot]
class RootStats {
  const RootStats._();

  /// {@macro fmtc.backend.listStores}
  Future<List<FMTCStore>> get storesAvailable async =>
      FMTCBackendAccess.internal
          .listStores()
          .then((s) => s.map(FMTCStore.new).toList());

  /// {@macro fmtc.backend.realSize}
  Future<double> get realSize async => FMTCBackendAccess.internal.realSize();

  /// {@macro fmtc.backend.rootSize}
  Future<double> get size async => FMTCBackendAccess.internal.rootSize();

  /// {@macro fmtc.backend.rootLength}
  Future<int> get length async => FMTCBackendAccess.internal.rootLength();

  /// {@macro fmtc.backend.watchRecovery}
  Stream<void> watchRecovery({
    bool triggerImmediately = false,
  }) async* {
    final stream = FMTCBackendAccess.internal.watchRecovery(
      triggerImmediately: triggerImmediately,
    );
    yield* stream;
  }

  /// {@macro fmtc.backend.watchStores}
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
