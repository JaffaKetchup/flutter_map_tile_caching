// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../backend.dart';

void _sharedWriteSingleTile({
  required Store root,
  required String storeName,
  required String url,
  required Uint8List bytes,
}) {
  final tiles = root.box<ObjectBoxTile>();
  final stores = root.box<ObjectBoxStore>();
  final rootBox = root.box<ObjectBoxRoot>();

  final tilesQuery = tiles.query(ObjectBoxTile_.url.equals(url)).build();
  final storeQuery =
      stores.query(ObjectBoxStore_.name.equals(storeName)).build();

  final storesToUpdate = <String, ObjectBoxStore>{};
  // If tile exists in this store, just update size, otherwise
  // length and size
  // Also update size of all related stores
  bool didContainAlready = false;

  root.runInTransaction(
    TxMode.write,
    () {
      final existingTile = tilesQuery.findUnique();
      final store = storeQuery.findUnique() ??
          (throw StoreNotExists(storeName: storeName));

      if (existingTile != null) {
        for (final relatedStore in existingTile.stores) {
          if (relatedStore.name == storeName) didContainAlready = true;

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
      } else {
        rootBox.put(
          rootBox.get(1)!
            ..length += 1
            ..size += bytes.lengthInBytes,
          mode: PutMode.update,
        );
      }

      if (!didContainAlready || existingTile == null) {
        storesToUpdate[storeName] = store
          ..length += 1
          ..size += bytes.lengthInBytes;
      }

      tiles.put(
        ObjectBoxTile(
          url: url,
          lastModified: DateTime.timestamp(),
          bytes: bytes,
        )..stores.addAll({store, ...?existingTile?.stores}),
      );
      stores.putMany(storesToUpdate.values.toList(), mode: PutMode.update);
    },
  );

  tilesQuery.close();
  storeQuery.close();
}
