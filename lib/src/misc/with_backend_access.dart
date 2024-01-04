// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

abstract base class _WithBackendAccess {
  const _WithBackendAccess(this._store);

  final FMTCStore _store;
  // ignore: invalid_use_of_protected_member
  FMTCBackendInternal get _backend => FMTC.instance.backend.internal;
  String get _storeName => _store.storeName;
}
