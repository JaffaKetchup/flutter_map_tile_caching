// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../backend.dart';

List<String> _sharedWriteSingleTile({
  required Store root,
  required List<String> storeNames,
  required String url,
  required Uint8List bytes,
  List<String>? writeAllNotIn,
}) {
  final tiles = root.box<ObjectBoxTile>();
  final storesBox = root.box<ObjectBoxStore>();
  final rootBox = root.box<ObjectBoxRoot>();

  if (writeAllNotIn != null) {
    storeNames.addAll(
      storesBox
          .getAll()
          .map((e) => e.name)
          .where((e) => !writeAllNotIn.contains(e) && !storeNames.contains(e)),
    );
  }

  final tilesQuery = tiles.query(ObjectBoxTile_.url.equals(url)).build();
  final storeQuery =
      storesBox.query(ObjectBoxStore_.name.oneOf(storeNames)).build();

  final storesToUpdate = <String, ObjectBoxStore>{};

  final createdIn = <String>{};

  root.runInTransaction(
    TxMode.write,
    () {
      final existingTile = tilesQuery.findUnique();
      final stores = storeQuery.find(); // Assumed not empty

      if (existingTile != null) {
        // If tile exists in this store, just update size, otherwise
        // length and size
        // Also update size of all related stores
        final didContainAlready = <String>{};

        for (final relatedStore in existingTile.stores) {
          didContainAlready
              .addAll(storeNames.where((s) => s == relatedStore.name));

          storesToUpdate[relatedStore.name] =
              (storesToUpdate[relatedStore.name] ?? relatedStore)
                ..size +=
                    -existingTile.bytes.lengthInBytes + bytes.lengthInBytes;
        }

        rootBox.put(
          rootBox.get(1)!
            ..size += -existingTile.bytes.lengthInBytes + bytes.lengthInBytes,
          mode: PutMode.update,
        );

        storesToUpdate.addEntries(
          stores.whereNot((s) => didContainAlready.contains(s.name)).map(
            (s) {
              createdIn.add(s.name);
              return MapEntry(
                s.name,
                s
                  ..length += 1
                  ..size += bytes.lengthInBytes,
              );
            },
          ),
        );
      } else {
        rootBox.put(
          rootBox.get(1)!
            ..length += 1
            ..size += bytes.lengthInBytes,
          mode: PutMode.update,
        );

        storesToUpdate.addEntries(
          stores.map(
            (s) {
              createdIn.add(s.name);
              return MapEntry(
                s.name,
                s
                  ..length += 1
                  ..size += bytes.lengthInBytes,
              );
            },
          ),
        );
      }

      tiles.put(
        ObjectBoxTile(
          url: url,
          lastModified: DateTime.timestamp(),
          bytes: bytes,
        )..stores.addAll({...stores, ...?existingTile?.stores}),
      );
      storesBox.putMany(storesToUpdate.values.toList(), mode: PutMode.update);
    },
  );

  tilesQuery.close();
  storeQuery.close();

  return createdIn.toList(growable: false);
}
