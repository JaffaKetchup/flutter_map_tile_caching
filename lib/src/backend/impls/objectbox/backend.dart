import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

import '../../../misc/exts.dart';
import '../../errors.dart';
import '../../interfaces/backend.dart';
import 'models/generated/objectbox.g.dart';
import 'models/models.dart';

/// Implementation of [FMTCBackend] that uses ObjectBox as the storage database
///
/// Only the factory constructor ([ObjectBoxBackend.new]), and
/// [friendlyIdentifier], should be used in end-applications. Other methods are
/// for internal use only.
class ObjectBoxBackend implements FMTCBackend {
  factory ObjectBoxBackend() => _instance;
  static final ObjectBoxBackend _instance = ObjectBoxBackend._();
  ObjectBoxBackend._();

  Store? _root; // Must not be closed if not `null`
  Store get _expectRoot => _root ?? (throw RootUnavailable());

  Future<ObjectBoxStore> _getStore(String name) async =>
      (await _expectRoot
          .box<ObjectBoxStore>()
          .query(ObjectBoxStore_.name.equals(name))
          .build()
          .findFirstAsync()) ??
      (throw StoreUnavailable(storeName: name));

  @override
  String get friendlyIdentifier => 'ObjectBox';

  @override
  @internal
  bool get supportsSharing => false;

  @override
  @internal
  Future<void> initialise({
    String? rootDirectory,
  }) async {
    final dir = await ((rootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(rootDirectory)) >>
            'fmtc')
        .create(recursive: true);
    _root = await openStore(directory: dir.absolute.path);
  }

  @override
  @internal
  Future<void> destroy({
    bool deleteRoot = false,
  }) async {
    _expectRoot;

    await Directory((_root!..close()).directoryPath).delete(recursive: true);
    _root = null;
  }

  @override
  @internal
  Future<void> createStore({
    required String storeName,
  }) async {
    await _expectRoot
        .box<ObjectBoxStore>()
        .putAsync(ObjectBoxStore(name: storeName), mode: PutMode.insert);
  }

  @override
  @internal
  Future<void> resetStore({
    required String storeName,
  }) async {
    _expectRoot;

    await _root!.runInTransactionAsync(
      TxMode.write,
      (store, storeName) {
        final tiles = _root!.box<ObjectBoxTile>();

        final removeIds = <int>[];

        final tilesBelongingToStore = (tiles.query()
              ..linkMany(ObjectBoxTile_.stores,
                  ObjectBoxStore_.name.equals(storeName)))
            .build();
        tiles.putMany(
          tilesBelongingToStore
              .find()
              .map((tile) {
                tile.stores.removeWhere((store) => store.name == storeName);
                if (tile.stores.isNotEmpty) return tile;
                removeIds.add(tile.id);
                return null;
              })
              .whereNotNull()
              .toList(),
          mode: PutMode.update,
        );
        tilesBelongingToStore.close();

        tiles.query(ObjectBoxTile_.id.oneOf(removeIds)).build()
          ..remove()
          ..close();
      },
      storeName,
    );
  }

  @override
  @internal
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) async =>
      _expectRoot
          .box<ObjectBoxStore>()
          .putAsync((await _getStore(currentStoreName))..name = newStoreName);

  @override
  @internal
  Future<void> deleteStore({
    required String storeName,
  }) async {
    //await resetStore(storeName: storeName);
    await _expectRoot
        .box<ObjectBoxStore>()
        .query(ObjectBoxStore_.name.equals(storeName))
        .build()
        .removeAsync();
  }

  @override
  @internal
  Future<List<ObjectBoxTile>> readTile({required String url}) async {
    final query = _expectRoot
        .box<ObjectBoxTile>()
        .query(ObjectBoxTile_.url.equals(url))
        .build();
    final tiles = await query.findAsync();
    query.close();
    return tiles;
  }

  @override
  @internal
  FutureOr<void> createTile() {}
  @override
  @internal
  FutureOr<void> updateTile() {}
  @override
  @internal
  FutureOr<void> deleteTile() {}

  @override
  @internal
  FutureOr<void> readLatestTile() {}
  @override
  @internal
  FutureOr<void> pruneTilesOlderThan({required DateTime expiry}) {}
}
