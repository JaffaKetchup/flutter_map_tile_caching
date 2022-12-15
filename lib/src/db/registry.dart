// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';
import 'defs/metadata.dart';
import 'defs/recovery.dart';
import 'defs/store.dart';
import 'defs/tile.dart';

/// Manages the tile stores available
///
/// The registry database contains a list of [DbStore]s, which as well as
/// containing some metadata, have an ID generated by the store name, which
/// refers to the independent database file of the same name, which contains
/// tiles.
///
/// It is very important for the registry to remain in sync with the actual state
/// of the root directory ([_directory]), otherwise data loss can easily occur.
/// See [synchronise]'s documentation for more information.
@internal
class FMTCRegistry {
  FMTCRegistry._({
    required String directory,
    required this.registryDatabase,
    required this.recoveryDatabase,
  }) : _directory = directory;
  final String _directory;

  static late FMTCRegistry instance;

  final Isar registryDatabase;
  final Isar recoveryDatabase;
  final Map<int, Isar> tileDatabases = {};

  static Future<FMTCRegistry> initialise({
    Directory? dirReal,
    String? dirString,
    required int databaseMaxSize,
  }) async {
    if (dirReal == null && dirString == null) {
      throw ArgumentError('Either `dirReal` or `dirString` should be provided');
    }

    final String directory = dirString ?? dirReal!.absolute.path;

    instance = FMTCRegistry._(
      directory: directory,
      registryDatabase: await Isar.open(
        [DbStoreSchema, DbTileSchema],
        name: 'registry',
        directory: directory,
        maxSizeMiB: databaseMaxSize,
      ),
      recoveryDatabase: await Isar.open(
        [DbRecoverableRegionSchema],
        name: 'recovery',
        directory: directory,
        maxSizeMiB: databaseMaxSize,
      ),
    );
    await instance.synchronise(databaseMaxSize: databaseMaxSize);

    return instance;
  }

  Future<void> uninitialise({bool delete = false}) async {
    await synchronise();
    await Future.wait<void>([
      ...tileDatabases.entries.map((e) async {
        await e.value.close(deleteFromDisk: delete);
        tileDatabases.remove(e.key);
      }),
      registryDatabase.close(deleteFromDisk: delete),
      recoveryDatabase.close(deleteFromDisk: delete),
    ]);
  }

  /// Synchronise the contents of the registry with the contents of the root
  /// directory
  ///
  /// To manage a store, see [StoreManagement]. Those methods change the state of
  /// the registry, then call this method to synchronise.
  ///
  /// Note that calling this method can lead to data loss - a tile store without
  /// a corresponding registry entry will be deleted without warning.
  Future<void> synchronise({int? databaseMaxSize}) async => Future.wait<void>([
        ...tileDatabases.entries.map((e) async {
          if (await registryDatabase.stores.get(e.key) == null) {
            tileDatabases.remove(e.key);
            if (e.value.isOpen) await e.value.close(deleteFromDisk: true);
          }
        }),
        ...(await registryDatabase.stores.where().findAll()).map((s) async {
          if (!tileDatabases.containsKey(s.id)) {
            tileDatabases[s.id] = await Isar.open(
              [DbTileSchema, DbMetadataSchema],
              name: s.id.toString(),
              directory: _directory,
              maxSizeMiB:
                  databaseMaxSize ?? FMTC.instance.settings.databaseMaxSize,
            );
          }
        }),
      ]);
}
