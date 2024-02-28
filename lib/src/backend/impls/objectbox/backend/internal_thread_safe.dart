// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

class _ObjectBoxBackendThreadSafeImpl implements FMTCBackendInternalThreadSafe {
  _ObjectBoxBackendThreadSafeImpl._({
    required this.storeReference,
  });

  final ByteData storeReference;
  Store? root;
  void get expectInitialised => root ?? (throw RootUnavailable());

  @override
  String get friendlyIdentifier => 'ObjectBox';

  @override
  void initialise() {
    if (root != null) throw RootAlreadyInitialised();
    root = Store.fromReference(getObjectBoxModel(), storeReference);
  }

  @override
  void uninitialise() {
    if (root == null) throw RootUnavailable();
    root!.close();
    root = null;
  }

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
    String? storeName,
  }) async {
    expectInitialised;

    final stores = root!.box<ObjectBoxTile>();

    final query = storeName == null
        ? stores.query(ObjectBoxTile_.url.equals(url)).build()
        : (stores.query(ObjectBoxTile_.url.equals(url))
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();

    final tile = query.findUnique();

    query.close();

    return tile;
  }

  @override
  void htWriteTile({
    required String storeName,
    required String url,
    required Uint8List bytes,
  }) {
    expectInitialised;

    final tiles = root!.box<ObjectBoxTile>();
    final stores = root!.box<ObjectBoxStore>();

    final tilesQuery = tiles.query(ObjectBoxTile_.url.equals(url)).build();
    final storeQuery =
        stores.query(ObjectBoxStore_.name.equals(storeName)).build();

    final storesToUpdate = <String, ObjectBoxStore>{};

    root!.runInTransaction(
      TxMode.write,
      () {
        final existingTile = tilesQuery.findUnique();
        final store = storeQuery.findUnique() ??
            (throw StoreNotExists(storeName: storeName));

        if (existingTile == null) {
          // If tile doesn't exist, just add to this store
          storesToUpdate[storeName] = store
            ..length += 1
            ..size += bytes.lengthInBytes;
        } else {
          // If tile exists in this store, just update size, otherwise
          // length and size
          // Also update size of all related stores
          bool didContainAlready = false;

          for (final relatedStore in existingTile.stores) {
            if (relatedStore.name == storeName) didContainAlready = true;

            storesToUpdate[relatedStore.name] =
                (storesToUpdate[relatedStore.name] ?? relatedStore)
                  ..size +=
                      -existingTile.bytes.lengthInBytes + bytes.lengthInBytes;
          }

          if (!didContainAlready) {
            storesToUpdate[storeName] = store
              ..length += 1
              ..size += bytes.lengthInBytes;
          }
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

  @override
  void htWriteTiles({
    required String storeName,
    required List<String> urls,
    required List<Uint8List> bytess,
  }) {
    expectInitialised;

    final tiles = root!.box<ObjectBoxTile>();
    final stores = root!.box<ObjectBoxStore>();

    final tilesQuery = tiles.query(ObjectBoxTile_.url.equals('')).build();
    final storeQuery =
        stores.query(ObjectBoxStore_.name.equals(storeName)).build();

    final storesToUpdate = <String, ObjectBoxStore>{};

    root!.runInTransaction(
      TxMode.write,
      () {
        final store = storeQuery.findUnique() ??
            (throw StoreNotExists(storeName: storeName));

        final tilesToUpdate = List.generate(
          urls.length,
          (i) {
            final existingTile = (tilesQuery
                  ..param(ObjectBoxTile_.url).value = urls[i])
                .findUnique();

            if (existingTile == null) {
              // If tile doesn't exist, just add to this store
              storesToUpdate[storeName] = (storesToUpdate[storeName] ?? store)
                ..length += 1
                ..size += bytess[i].lengthInBytes;
            } else {
              // If tile exists in this store, just update size, otherwise
              // length and size
              // Also update size of all related stores
              bool didContainAlready = false;

              for (final relatedStore in existingTile.stores) {
                if (relatedStore.name == storeName) didContainAlready = true;

                storesToUpdate[relatedStore.name] =
                    (storesToUpdate[relatedStore.name] ?? relatedStore)
                      ..size += -existingTile.bytes.lengthInBytes +
                          bytess[i].lengthInBytes;
              }

              if (!didContainAlready) {
                storesToUpdate[storeName] = store
                  ..length += 1
                  ..size += bytess[i].lengthInBytes;
              }
            }

            return ObjectBoxTile(
              url: urls[i],
              lastModified: DateTime.timestamp(),
              bytes: bytess[i],
            )..stores.addAll({store, ...?existingTile?.stores});
          },
          growable: false,
        );

        tiles.putMany(tilesToUpdate);
        stores.putMany(storesToUpdate.values.toList(), mode: PutMode.update);
      },
    );

    tilesQuery.close();
    storeQuery.close();
  }
}
