// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../../../../flutter_map_tile_caching.dart';

/// {@macro fmtc.backend.objectbox}
final class FMTCObjectBoxBackend implements FMTCBackend {
  static const _noopMessage =
      'FMTC is not supported on non-FFI platforms by default';

  /// {@macro fmtc.backend.initialise}
  ///
  /// {@macro fmtc.backend.objectbox.initialise}
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
  /// {@macro fmtc.backend.objectbox.uninitialise}
  @override
  Future<void> uninitialise({
    bool deleteRoot = false,
    bool immediate = false,
  }) =>
      throw UnsupportedError(_noopMessage);
}
