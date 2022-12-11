// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'directory.dart';

class _RootAccess {
  /// Store registry database
  late Isar rootDb;

  /// Tiles databases
  final Map<String, Isar> storeDbs = {};

  /// Ensure that [storeDbs] contains the (open) stores that are in the [rootDb]
  /// registry
  ///
  /// If a store is not found in the registry, it is closed, deleted, and
  /// removed. If a new store is found in the registry, it is opened and added.
  Future<void> rescan() async {
    if (!await FMTC.instance.rootDirectory.manage.readyAsync) {
      return storeDbs.clear();
    }

    await Future.wait<void>(
      storeDbs.values.map((s) async {
        if (await rootDb.stores.get(databaseHash(s.name)) == null) {
          storeDbs.remove(s.name);
          await s.close(deleteFromDisk: true);
        }
      }),
    );
    await Future.wait<void>(
      (await rootDb.stores.where().findAll()).map((s) async {
        if (!storeDbs.containsKey(s.name)) {
          storeDbs[s.name] = await Isar.open(
            [TileSchema],
            name: s.name,
            directory: FMTC.instance.rootDirectory.rootDirectory.absolute.path,
          );
        }
      }),
    );
  }

  /// Register a store and rescan to create its tile database
  Future<void> createStore(String name, {bool autoRescan = true}) async {
    await rootDb.writeTxn(() => rootDb.stores.put(Store(name: name)));
    if (autoRescan) await rescan();
  }

  /// Unregister a store and rescan to delete its tile database
  Future<void> deleteStore(String name, {bool autoRescan = true}) async {
    await rootDb.writeTxn(() => rootDb.stores.delete(databaseHash(name)));
    if (autoRescan) await rescan();
  }
}
