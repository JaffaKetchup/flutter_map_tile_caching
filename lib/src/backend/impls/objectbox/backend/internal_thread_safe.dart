// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of 'backend.dart';

class _ObjectBoxBackendThreadSafeImpl implements FMTCBackendInternalThreadSafe {
  _ObjectBoxBackendThreadSafeImpl._({
    required this.storeReference,
  });

  @override
  String get friendlyIdentifier => 'ObjectBox';

  void get expectInitialised => root ?? (throw RootUnavailable());

  final ByteData storeReference;
  Store? root;

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
    final rootBox = root!.box<ObjectBoxRoot>();

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

        // If tile exists in this store, just update size, otherwise
        // length and size
        // Also update size of all related stores
        bool didContainAlready = false;

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
        }

        if (!didContainAlready || existingTile == null) {
          storesToUpdate[storeName] = store
            ..length += 1
            ..size += bytes.lengthInBytes;

          rootBox.put(
            rootBox.get(1)!
              ..length += 1
              ..size += bytes.lengthInBytes,
            mode: PutMode.update,
          );
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
    final rootBox = root!.box<ObjectBoxRoot>();

    final tilesQuery = tiles.query(ObjectBoxTile_.url.equals('')).build();
    final storeQuery =
        stores.query(ObjectBoxStore_.name.equals(storeName)).build();

    final storesToUpdate = <String, ObjectBoxStore>{};

    root!.runInTransaction(
      TxMode.write,
      () {
        final rootData = rootBox.get(1)!;
        final store = storeQuery.findUnique() ??
            (throw StoreNotExists(storeName: storeName));

        for (int i = 0; i <= urls.length - 1; i++) {
          final url = urls[i];
          final bytes = bytess[i];

          final existingTile =
              (tilesQuery..param(ObjectBoxTile_.url).value = url).findUnique();

          // If tile exists in this store, just update size, otherwise
          // length and size
          // Also update size of all related stores
          bool didContainAlready = false;

          if (existingTile != null) {
            for (final relatedStore in existingTile.stores) {
              if (relatedStore.name == storeName) didContainAlready = true;

              storesToUpdate[relatedStore.name] =
                  (storesToUpdate[relatedStore.name] ?? relatedStore)
                    ..size +=
                        -existingTile.bytes.lengthInBytes + bytes.lengthInBytes;
            }

            rootData.size +=
                -existingTile.bytes.lengthInBytes + bytes.lengthInBytes;
          }

          if (!didContainAlready || existingTile == null) {
            storesToUpdate[storeName] = store
              ..length += 1
              ..size += bytes.lengthInBytes;

            rootData
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
        }

        rootBox.put(rootData, mode: PutMode.update);
        stores.putMany(storesToUpdate.values.toList(), mode: PutMode.update);
      },
    );

    tilesQuery.close();
    storeQuery.close();
  }
}
