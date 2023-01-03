// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'defs/metadata.dart';
import 'defs/recovery.dart';
import 'defs/store_descriptor.dart';
import 'defs/tile.dart';

/// Manages the stores available
///
/// It is very important for the [storeDatabases] state to remain in sync with
/// the actual state of the [directory], otherwise unexpected behaviour may
/// occur.
@internal
class FMTCRegistry {
  const FMTCRegistry._({
    required this.directory,
    required this.recoveryDatabase,
    required this.storeDatabases,
  });

  static late FMTCRegistry instance;

  final Directory directory;
  final Isar recoveryDatabase;
  final Map<int, Isar> storeDatabases;

  static Future<FMTCRegistry> initialise({
    required Directory directory,
    required int databaseMaxSize,
    required CompactCondition? databaseCompactCondition,
  }) async =>
      instance = FMTCRegistry._(
        directory: directory,
        recoveryDatabase: await Isar.open(
          [DbRecoverableRegionSchema],
          name: '.recovery',
          directory: directory.absolute.path,
          maxSizeMiB: databaseMaxSize,
          compactOnLaunch: databaseCompactCondition,
        ),
        storeDatabases: Map.fromEntries(
          await Future.wait(
            await directory
                .list()
                .where(
                  (e) =>
                      e is File &&
                      !path.basename(e.path).startsWith('.') &&
                      !path.basename(e.path).endsWith('-lck'),
                )
                .map((f) async {
              final id = path.basenameWithoutExtension(f.path);
              return MapEntry(
                int.parse(id),
                await Isar.open(
                  [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
                  name: id,
                  directory: directory.absolute.path,
                  maxSizeMiB: databaseMaxSize,
                  compactOnLaunch: databaseCompactCondition,
                ),
              );
            }).toList(),
          ),
        ),
      );

  Future<void> uninitialise({bool delete = false}) async {
    await Future.wait<void>([
      ...storeDatabases.entries.map((e) async {
        await e.value.close(deleteFromDisk: delete);
        storeDatabases.remove(e.key);
      }),
      recoveryDatabase.close(deleteFromDisk: delete),
    ]);
  }
}
