// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../backend.dart';

class _ObjectBoxBackendThreadSafeImpl implements FMTCBackendInternalThreadSafe {
  _ObjectBoxBackendThreadSafeImpl._({
    required this.rootDirectory,
  });

  @override
  String get friendlyIdentifier => 'ObjectBox';

  final String rootDirectory;
  Store get expectInitialisedRoot => _root ?? (throw RootUnavailable());
  Store? _root;

  @override
  void initialise() {
    if (_root != null) throw RootAlreadyInitialised();
    _root = Store.attach(getObjectBoxModel(), rootDirectory);
  }

  @override
  void uninitialise() {
    expectInitialisedRoot.close();
    _root = null;
  }

  @override
  _ObjectBoxBackendThreadSafeImpl duplicate() =>
      _ObjectBoxBackendThreadSafeImpl._(rootDirectory: rootDirectory);

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
    String? storeName,
  }) async {
    final stores = expectInitialisedRoot.box<ObjectBoxTile>();

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
  void writeTile({
    required String storeName,
    required String url,
    required Uint8List bytes,
  }) =>
      _sharedWriteSingleTile(
        root: expectInitialisedRoot,
        storeNames: [storeName],
        url: url,
        bytes: bytes,
      );

  @override
  void writeTiles({
    required String storeName,
    required List<String> urls,
    required List<Uint8List> bytess,
  }) {
    expectInitialisedRoot;

    final tiles = _root!.box<ObjectBoxTile>();
    final stores = _root!.box<ObjectBoxStore>();
    final rootBox = _root!.box<ObjectBoxRoot>();

    final tilesQuery = tiles.query(ObjectBoxTile_.url.equals('')).build();
    final storeQuery =
        stores.query(ObjectBoxStore_.name.equals(storeName)).build();

    final storesToUpdate = <String, ObjectBoxStore>{};

    _root!.runInTransaction(
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
          } else {
            rootData
              ..length += 1
              ..size += bytes.lengthInBytes;
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
        }

        rootBox.put(rootData, mode: PutMode.update);
        stores.putMany(storesToUpdate.values.toList(), mode: PutMode.update);
      },
    );

    tilesQuery.close();
    storeQuery.close();
  }

  @override
  void startRecovery({
    required int id,
    required String storeName,
    required DownloadableRegion region,
    required int endTile,
  }) {
    expectInitialisedRoot;

    ObjectBoxRecoveryRegion recursiveWriteRecoveryRegions(BaseRegion region) {
      final recoveryRegion = ObjectBoxRecoveryRegion.fromRegion(region: region);

      if (region case final MultiRegion region) {
        recoveryRegion.multiLinkedRegions
            .addAll(region.regions.map(recursiveWriteRecoveryRegions));
      }

      _root!
          .box<ObjectBoxRecoveryRegion>()
          .put(recoveryRegion, mode: PutMode.insert);

      return recoveryRegion;
    }

    _root!.runInTransaction(
      TxMode.write,
      () => _root!.box<ObjectBoxRecovery>().put(
            ObjectBoxRecovery.fromRegion(
              refId: id,
              storeName: storeName,
              region: region,
              endTile: endTile,
              target: recursiveWriteRecoveryRegions(region.originalRegion),
            ),
            mode: PutMode.insert,
          ),
    );
  }

  @override
  void updateRecovery({
    required int id,
    required int newStartTile,
  }) {
    expectInitialisedRoot;

    final existingRecoveryQuery = _root!
        .box<ObjectBoxRecovery>()
        .query(ObjectBoxRecovery_.refId.equals(id))
        .build();

    _root!.runInTransaction(
      TxMode.write,
      () {
        _root!.box<ObjectBoxRecovery>().put(
              existingRecoveryQuery.findUnique()!..startTile = newStartTile,
              mode: PutMode.update,
            );
      },
    );

    existingRecoveryQuery.close();
  }
}
