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

    Future<void> deleteDatabaseAndRelatedFiles(String base) async {
      try {
        await Future.wait(
          await directory
              .list()
              .where((e) => e is File && p.basename(e.path).startsWith(base))
              .map((e) async {
            if (await e.exists()) return e.delete();
          }).toList(),
        );
        // ignore: empty_catches
      } catch (e) {}
    }

    Future<void> registerSafeDatabase(String base) async {
      initialisationSafetyWriteSink?.writeln(base);
      await initialisationSafetyWriteSink?.flush();
    }

    // Prepare open database method
    Future<MapEntry<int, Isar>?> openIsar(String id, File file) async {
      try {
        return MapEntry(
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
      } catch (err) {
        await deleteDatabaseAndRelatedFiles(p.basename(file.path));
        errorHandler?.call(
          FMTCInitialisationException(
            'Failed to initialise a store because Isar failed to open the database.',
            FMTCInitialisationExceptionType.isarFailure,
            originalError: err,
          ),
        );
        return null;
      }
    }

    // Open recovery database
    if (!(safeModeSuccessfulIDs?.contains('.recovery') ?? true) &&
        await (directory >>> '.recovery.isar').exists()) {
      await deleteDatabaseAndRelatedFiles('.recovery');
      hasLocatedCorruption = true;
      errorHandler?.call(
        FMTCInitialisationException(
          'Failed to open a database because it was not listed as safe/stable on last initialisation.',
          FMTCInitialisationExceptionType.corruptedDatabase,
          storeName: '.recovery',
        ),
      );
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
            .asyncMap((file) async {
              final id = p.basenameWithoutExtension(file.path);
              final path = p.basename(file.path);

              // Check whether the database is safe
              if (!hasLocatedCorruption &&
                  safeModeSuccessfulIDs != null &&
                  !safeModeSuccessfulIDs.contains(id)) {
                await deleteDatabaseAndRelatedFiles(path);
                hasLocatedCorruption = true;
                errorHandler?.call(
                  FMTCInitialisationException(
                    'Failed to open a database because it was not listed as safe/stable on last initialisation.',
                    FMTCInitialisationExceptionType.corruptedDatabase,
                  ),
                );
                return null;
              }

              // Open the database
              MapEntry<int, Isar>? entry = await openIsar(id, file as File);
              if (entry == null) return null;

              // Correct the database ID (filename) if the store name doesn't
              // match
              final storeName = (await entry.value.descriptor).name;
              final realId = DatabaseTools.hash(storeName);
              if (realId != int.parse(id)) {
                await entry.value.close();
                file = await file
                    .rename(Directory(p.dirname(file.path)) > '$realId.isar');
                entry = await openIsar(realId.toString(), file);
                await deleteDatabaseAndRelatedFiles(path);
              }

              // Register the database as safe and add it to the registry
              await registerSafeDatabase(id);
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
