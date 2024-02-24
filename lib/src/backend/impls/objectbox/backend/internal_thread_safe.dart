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

    final storeAdjustments = <String, ({int deltaSize, int deltaLength})>{};

    root!.runInTransaction(
      TxMode.write,
      () {
        final store = storeQuery.findUnique()!;

        final existingTile =
            (tilesQuery..param(ObjectBoxTile_.url).value = url).findUnique();

        storeAdjustments[storeName] = storeAdjustments[storeName] == null
            ? (deltaLength: 1, deltaSize: bytes.lengthInBytes)
            : (
                deltaLength: storeAdjustments[storeName]!.deltaLength + 1,
                deltaSize: storeAdjustments[storeName]!.deltaSize +
                    bytes.lengthInBytes,
              );

        if (existingTile != null) {
          for (final store in existingTile.stores) {
            storeAdjustments[store.name] = storeAdjustments[store.name] == null
                ? (
                    deltaLength: 0,
                    deltaSize:
                        -existingTile.bytes.lengthInBytes + bytes.lengthInBytes,
                  )
                : (
                    deltaLength: storeAdjustments[store.name]!.deltaLength,
                    deltaSize: storeAdjustments[store.name]!.deltaSize +
                        (-existingTile.bytes.lengthInBytes +
                            bytes.lengthInBytes),
                  );
          }
        }

        tiles.put(
          ObjectBoxTile(
            url: url,
            lastModified: DateTime.timestamp(),
            bytes: bytes,
          )..stores.addAll(
              {
                store,
                if (existingTile != null) ...existingTile.stores,
              },
            ),
        );

        stores.putMany(
          storeAdjustments.entries
              .map(
                (e) => store
                  ..length += e.value.deltaLength
                  ..size += e.value.deltaSize,
              )
              .toList(),
        );
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
    final storeQuery = stores.query(ObjectBoxStore_.name.equals('')).build();

    final storeAdjustments = <String, ({int deltaSize, int deltaLength})>{};

    root!.runInTransaction(
      TxMode.write,
      () {
        final store = (storeQuery
              ..param(ObjectBoxStore_.name).value = storeName)
            .findUnique()!;

        tiles.putMany(
          List.generate(
            urls.length,
            (i) {
              final existingTile = (tilesQuery
                    ..param(ObjectBoxTile_.url).value = urls[i])
                  .findUnique();

              storeAdjustments[storeName] = storeAdjustments[storeName] == null
                  ? (deltaLength: 1, deltaSize: bytess[i].lengthInBytes)
                  : (
                      deltaLength: storeAdjustments[storeName]!.deltaLength + 1,
                      deltaSize: storeAdjustments[storeName]!.deltaSize +
                          bytess[i].lengthInBytes,
                    );

              if (existingTile != null) {
                for (final store in existingTile.stores) {
                  storeAdjustments[store.name] =
                      storeAdjustments[store.name] == null
                          ? (
                              deltaLength: 0,
                              deltaSize: -existingTile.bytes.lengthInBytes +
                                  bytess[i].lengthInBytes,
                            )
                          : (
                              deltaLength:
                                  storeAdjustments[store.name]!.deltaLength,
                              deltaSize:
                                  storeAdjustments[store.name]!.deltaSize +
                                      (-existingTile.bytes.lengthInBytes +
                                          bytess[i].lengthInBytes),
                            );
                }
              }

              return ObjectBoxTile(
                url: urls[i],
                lastModified: DateTime.timestamp(),
                bytes: bytess[i],
              )..stores.addAll(
                  {
                    store,
                    if (existingTile != null) ...existingTile.stores,
                  },
                );
            },
            growable: false,
          ),
        );

        assert(
          storeAdjustments.isNotEmpty,
          '`storeAdjustments` should not be empty if relations are being set correctly',
        );

        stores.putMany(
          storeAdjustments.entries
              .map(
                (e) => (storeQuery..param(ObjectBoxStore_.name).value = e.key)
                    .findUnique()!
                  ..length += e.value.deltaLength
                  ..size += e.value.deltaSize,
              )
              .toList(),
        );
      },
    );

    tilesQuery.close();
    storeQuery.close();
  }
}
