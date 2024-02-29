// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';

import '../../export_internal.dart';

/// {@template fmtc.backend.backend}
/// An abstract interface that FMTC will use to communicate with a storage
/// 'backend' (usually one root)
///
/// See also [FMTCBackendInternal] and [FMTCBackendInternalThreadSafe], which
/// have the actual method signatures. This is provided as a public means to
/// initialise and uninitialise the backend.
///
/// When creating a custom implementation, follow the same pattern as the
/// built-in ObjectBox backend ([FMTCObjectBoxBackend]).
/// {@endtemplate}
abstract interface class FMTCBackend {
  /// {@macro fmtc.backend.backend}
  ///
  /// This constructor does not initialise this backend, also invoke
  /// [initialise].
  const FMTCBackend();

  /// {@template fmtc.backend.initialise}
  /// Initialise this backend, and create the root
  ///
  /// Prefer to leave [rootDirectory] as null, which will use
  /// `getApplicationDocumentsDirectory()`. Alternatively, pass a custom
  /// directory - it is recommended to not use a typical cache directory, as the
  /// OS can clear these without notice at any time.
  /// {@endtemplate}
  Future<void> initialise({
    String? rootDirectory,
  });

  /// {@template fmtc.backend.uninitialise}
  /// Uninitialise this backend, and release whatever resources it is consuming
  ///
  /// If [deleteRoot] is `true`, then the root will be permanently deleted.
  /// {@endtemplate}
  Future<void> uninitialise({
    bool deleteRoot = false,
  });
}
