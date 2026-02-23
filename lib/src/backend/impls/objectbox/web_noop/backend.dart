// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../../../../../flutter_map_tile_caching.dart';

/// Implementation of [FMTCBackend] that uses ObjectBox as the storage database
///
/// On web, this redirects to a no-op implementation that throws
/// [UnsupportedError]s when attempting to use [initialise] or [uninitialise],
/// and [RootUnavailable] when trying to use any other method.
final class FMTCObjectBoxBackend implements FMTCBackend {
  static const _noopMessage =
      'FMTC is not supported on non-FFI platforms by default';

  /// {@macro fmtc.backend.initialise}
  ///
  /// ---
  ///
  /// [maxDatabaseSize] is the maximum size the database file can grow
  /// to, in KB. Exceeding it throws `DbFullException` (from
  /// 'package:objectbox') on write operations. Defaults to 10 GB (10000000 KB).
  ///
  /// [macosApplicationGroup] should be set when creating a sandboxed macOS app,
  /// specify the application group (of less than 20 chars). See
  /// [the ObjectBox docs](https://docs.objectbox.io/getting-started) for
  /// details.
  ///
  /// [rootIsolateToken] should only be used in exceptional circumstances where
  /// this backend is being initialised in a seperate isolate (or background)
  /// thread.
  ///
  /// Avoid using [useInMemoryDatabase] outside of testing purposes.
  @override
  Future<void> initialise({
    String? rootDirectory,
    int maxDatabaseSize = 10000000,
    String? macosApplicationGroup,
    RootIsolateToken? rootIsolateToken,
    @visibleForTesting bool useInMemoryDatabase = false,
  }) =>
      throw UnsupportedError(_noopMessage);

  /// {@macro fmtc.backend.uninitialise}
  ///
  /// If [immediate] is `true`, any operations currently underway will be lost,
  /// as the worker will be killed as quickly as possible (not necessarily
  /// instantly).
  /// If `false`, all operations currently underway will be allowed to complete,
  /// but any operations started after this method call will be lost.
  @override
  Future<void> uninitialise({
    bool deleteRoot = false,
    bool immediate = false,
  }) =>
      throw UnsupportedError(_noopMessage);
}
