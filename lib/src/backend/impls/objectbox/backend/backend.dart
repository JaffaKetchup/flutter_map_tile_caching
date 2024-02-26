// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../../flutter_map_tile_caching.dart';
import '../../../export_internal.dart';
import '../models/generated/objectbox.g.dart';
import '../models/src/recovery.dart';
import '../models/src/store.dart';
import '../models/src/tile.dart';

export 'package:objectbox/objectbox.dart' show StorageException;

part 'internal_thread_safe.dart';
part 'internal.dart';
part 'internal_worker.dart';

/// Implementation of [FMTCBackend] that uses ObjectBox as the storage database
final class FMTCObjectBoxBackend implements FMTCBackend {
  /// {@macro fmtc.backend.initialise}
  ///
  /// Consider handling [StorageException], which is an exception thrown by
  /// ObjectBox which indicates an issue when reading/writing data to the
  /// database - for example, due to exceeding the [maxDatabaseSize].
  ///
  /// ---
  ///
  /// [maxDatabaseSize] is the maximum size the database file can grow
  /// to, in KB. Exceeding it throws [DbFullException]. Defaults to 10 GB.
  ///
  /// [macosApplicationGroup] should be set when creating a sandboxed macOS app,
  /// specify the application group (of less than 20 chars). See
  /// [the ObjectBox docs](https://docs.objectbox.io/getting-started) for
  /// details.
  @override
  Future<void> initialise({
    String? rootDirectory,
    int maxDatabaseSize = 10000000,
    String? macosApplicationGroup,
    FMTCExceptionHandler? exceptionHandler,
  }) =>
      FMTCObjectBoxBackendInternal._instance.initialise(
        rootDirectory: rootDirectory,
        maxDatabaseSize: maxDatabaseSize,
        macosApplicationGroup: macosApplicationGroup,
        exceptionHandler: exceptionHandler,
      );

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
      FMTCObjectBoxBackendInternal._instance
          .uninitialise(deleteRoot: deleteRoot, immediate: immediate);
}
