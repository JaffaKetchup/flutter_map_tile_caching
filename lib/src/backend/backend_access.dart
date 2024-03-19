// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart' as meta;

import 'export_external.dart';

/// Provides access to the thread-seperate backend internals
/// ([FMTCBackendInternal]) globally with some level of access control
///
/// {@template fmtc.backend.access}
///
/// Only a single backend may set the [internal] backend at any one time,
/// essentially providing a locking mechanism preventing multiple backends from
/// being used at the same time (with a shared access).
///
/// A [FMTCBackendInternal] implementation can access the [internal] setters,
/// and should set them both sequentially at the end of the
/// [FMTCBackend.initialise] & [FMTCBackend.uninitialise] implementations.
///
/// The [internal] getter(s) should never be used outside of FMTC internals, as
/// it provides access to potentially uncontrolled, and unorganised, methods.
/// {@endtemplate}
abstract mixin class FMTCBackendAccess {
  static FMTCBackendInternal? _internal;

  /// Provides access to the thread-seperate backend internals
  /// ([FMTCBackendInternal]) globally with some level of access control
  ///
  /// {@macro fmtc.backend.access}
  @meta.internal
  @meta.experimental
  static FMTCBackendInternal get internal =>
      _internal ?? (throw RootUnavailable());

  @meta.protected
  static set internal(FMTCBackendInternal? newInternal) {
    if (newInternal != null && _internal != null) {
      throw RootAlreadyInitialised();
    }
    _internal = newInternal;
  }
}

/// Provides access to the thread-seperate backend internals
/// ([FMTCBackendInternalThreadSafe]) globally with some level of access control
///
/// {@macro fmtc.backend.access}
abstract mixin class FMTCBackendAccessThreadSafe {
  static FMTCBackendInternalThreadSafe? _internal;

  /// Provides access to the thread-seperate backend internals
  /// ([FMTCBackendInternalThreadSafe]) globally with some level of access control
  ///
  /// {@macro fmtc.backend.access}
  @meta.internal
  @meta.experimental
  static FMTCBackendInternalThreadSafe get internal =>
      _internal ?? (throw RootUnavailable());

  @meta.protected
  static set internal(FMTCBackendInternalThreadSafe? newInternal) {
    if (newInternal != null && _internal != null) {
      throw RootAlreadyInitialised();
    }
    _internal = newInternal;
  }
}
