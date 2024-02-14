// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

abstract base class _WithBackendAccess {
  const _WithBackendAccess(this._store);

  final FMTCStore _store;
  FMTCBackendInternal get _backend => FMTCBackendAccess.internal;
  String get _storeName => _store.storeName;
}
