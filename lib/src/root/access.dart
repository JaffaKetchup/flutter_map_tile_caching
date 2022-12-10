// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'directory.dart';

class _RootAccess {
  Directory get directory => FMTC.instance.rootDirectory.rootDirectory;

  late final Isar rootDb;
  final Map<String, Isar> storeDbs = {};

  Future<void> rescan() async {
    storeDbs
      ..clear()
      ..addEntries(
        (await Future.wait(
          (await rootDb.stores.where().findAll()).map(
            (s) => Isar.open(
              [TileSchema],
              name: s.name,
              directory: directory.absolute.path,
            ),
          ),
        ))
            .map((e) => MapEntry(e.name, e)),
      );
  }

  Future<void> createStore(String name) async {
    await rootDb.writeTxn(() => rootDb.stores.put(Store(name: name)));
    await rescan();
  }

  Future<void> deleteStore(String name) async {
    await rootDb.writeTxn(() => rootDb.stores.delete(databaseHash(name)));
    await rescan();
  }
}
