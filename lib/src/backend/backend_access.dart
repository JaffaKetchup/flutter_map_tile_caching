// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart' as meta;

import 'export_internal.dart';

/// Provides access to the backend in use throughout FMTC internals
///
/// Designed to allow a single backend to set and control the context at once.
///
/// Avoid using externally. Never set `context` externally.
@meta.internal
abstract mixin class FMTCBackendAccess {
  static FMTCBackendInternal? _internal;

  @meta.internal
  @meta.experimental
  static FMTCBackendInternal get internal =>
      _internal ?? (throw RootUnavailable());

  @meta.internal
  @meta.protected
  static set internal(FMTCBackendInternal? newInternal) {
    if (newInternal != null && _internal != null) {
      throw RootAlreadyInitialised();
    }
    _internal = newInternal;
  }
}

@meta.internal
abstract mixin class FMTCBackendAccessThreadSafe {
  static FMTCBackendInternalThreadSafe? _internal;

  @meta.internal
  @meta.experimental
  static FMTCBackendInternalThreadSafe get internal =>
      _internal ?? (throw RootUnavailable());

  @meta.internal
  @meta.protected
  static set internal(FMTCBackendInternalThreadSafe? newInternal) {
    if (newInternal != null && _internal != null) {
      throw RootAlreadyInitialised();
    }
    _internal = newInternal;
  }
}
