// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';

import '../../flutter_map_tile_caching.dart';
import '../misc/exts.dart';
import 'defs/metadata.dart';
import 'defs/recovery.dart';
import 'defs/store_descriptor.dart';
import 'defs/tile.dart';
import 'tools.dart';

/// Manages the stores available
///
/// It is very important for the [_storeDatabases] state to remain in sync with
/// the actual state of the [directory], otherwise unexpected behaviour may
/// occur.
@internal
class FMTCRegistry {
  const FMTCRegistry._({
    required this.directory,
    required this.recoveryDatabase,
    required Map<int, Isar> storeDatabases,
  }) : _storeDatabases = storeDatabases;

  static late FMTCRegistry instance;

  final Directory directory;
  final Isar recoveryDatabase;
  final Map<int, Isar> _storeDatabases;

  static Future<FMTCRegistry> initialise({
    required Directory directory,
    required int databaseMaxSize,
    required CompactCondition? databaseCompactCondition,
    required void Function(FMTCInitialisationException error)? errorHandler,
    required IOSink? initialisationSafetyWriteSink,
    required List<String>? safeModeSuccessfulIDs,
    required bool debugMode,
  }) async {
    // Set up initialisation safety features
    bool hasLocatedCorruption = false;

    Future<void> deleteCorruptedDatabases(String base) async {
      try {
        await Future.wait(
          await directory
              .list()
              .where((e) => e is File && p.basename(e.path).startsWith(base))
              .map((e) async {
            if (await e.exists()) return e.delete();
          }).toList(),
        );
      } finally {
        hasLocatedCorruption = true;
        errorHandler?.call(FMTCInitialisationException(source: null));
      }
    }

    Future<void> registerSafeDatabase(String base) async {
      initialisationSafetyWriteSink?.writeln(base);
      await initialisationSafetyWriteSink?.flush();
    }

    // Open recovery database
    if (!(safeModeSuccessfulIDs?.contains('.recovery') ?? true) &&
        await (directory >>> '.recovery.isar').exists()) {
      await deleteCorruptedDatabases('.recovery');
    }
    final recoveryDatabase = await Isar.open(
      [
        DbRecoverableRegionSchema,
        if (debugMode) ...[
          DbStoreDescriptorSchema,
          DbTileSchema,
          DbMetadataSchema,
        ],
      ],
      name: '.recovery',
      directory: directory.absolute.path,
      maxSizeMiB: databaseMaxSize,
      compactOnLaunch: databaseCompactCondition,
      inspector: debugMode,
    );
    await registerSafeDatabase('.recovery');

    // Open store databases
    return instance = FMTCRegistry._(
      directory: directory,
      recoveryDatabase: recoveryDatabase,
      storeDatabases: Map.fromEntries(
        await directory
            .list()
            .where(
              (e) =>
                  e is File &&
                  !p.basename(e.path).startsWith('.') &&
                  p.extension(e.path) == '.isar',
            )
            .asyncMap((f) async {
              final id = p.basenameWithoutExtension(f.path);

              if (!hasLocatedCorruption &&
                  safeModeSuccessfulIDs != null &&
                  !safeModeSuccessfulIDs.contains(id)) {
                await deleteCorruptedDatabases(p.basename(f.path));
                return null;
              }

              if (int.tryParse(id) == null) return null;

              final MapEntry<int, Isar> entry;
              try {
                entry = MapEntry(
                  int.parse(id),
                  await Isar.open(
                    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
                    name: id,
                    directory: directory.absolute.path,
                    maxSizeMiB: databaseMaxSize,
                    compactOnLaunch: databaseCompactCondition,
                    inspector: debugMode,
                  ),
                );
                await registerSafeDatabase(id);
              } catch (err) {
                errorHandler?.call(FMTCInitialisationException(source: err));
                return null;
              }

              return entry;
            })
            .whereNotNull()
            .toList(),
      ),
    );
  }

  Future<void> uninitialise({bool delete = false}) async {
    await Future.wait<void>([
      ...FMTC.instance.rootDirectory.stats.storesAvailable
          .map((s) => s.manage.delete()),
      recoveryDatabase.close(deleteFromDisk: delete),
    ]);
  }

  Isar call(String storeName) {
    final id = DatabaseTools.hash(storeName);
    final isRegistered = _storeDatabases.containsKey(id);
    if (!(isRegistered && _storeDatabases[id]!.isOpen)) {
      throw FMTCStoreNotReady(
        storeName: storeName,
        registered: isRegistered,
      );
    }
    return _storeDatabases[id]!;
  }

  Isar register(int id, Isar db) => _storeDatabases[id] = db;
  Isar? unregister(int id) => _storeDatabases.remove(id);
  Map<int, Isar> get storeDatabases => _storeDatabases;
}
