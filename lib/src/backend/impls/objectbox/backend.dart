import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';

import '../../../misc/exts.dart';
import '../../errors.dart';
import '../../interfaces/backend.dart';
import 'models/generated/objectbox.g.dart';
import 'models/models.dart';

/// Implementation of [FMTCBackend] that uses ObjectBox as the storage database
abstract interface class ObjectBoxBackend implements FMTCBackend {
  /// Implementation of [FMTCBackend] that uses ObjectBox as the storage
  /// database
  factory ObjectBoxBackend() => _instance;
  static final _instance = _ObjectBoxBackendImpl._();
}

class _ObjectBoxBackendImpl implements ObjectBoxBackend {
  _ObjectBoxBackendImpl._();

  Store? root; // Must not be closed if not `null`
  Store get expectRoot => root ?? (throw RootUnavailable());

  Future<ObjectBoxStore> getStore(String name) async =>
      (await expectRoot
          .box<ObjectBoxStore>()
          .query(ObjectBoxStore_.name.equals(name))
          .build()
          .findUniqueAsync()) ??
      (throw StoreUnavailable(storeName: name));

  @override
  String get friendlyIdentifier => 'ObjectBox';

  @override
  Future<void> initialise({
    String? rootDirectory,
  }) async {
    final dir = await ((rootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(rootDirectory)) >>
            'fmtc')
        .create(recursive: true);
    root = await openStore(directory: dir.absolute.path);
  }

  @override
  Future<void> destroy({
    bool deleteRoot = false,
  }) async {
    expectRoot;

    await Directory((root!..close()).directoryPath).delete(recursive: true);
    root = null;
  }

  @override
  Future<void> createStore({
    required String storeName,
  }) async {
    await expectRoot
        .box<ObjectBoxStore>()
        .putAsync(ObjectBoxStore(name: storeName), mode: PutMode.insert);
  }

  @override
  Future<void> resetStore({
    required String storeName,
  }) async {
    expectRoot;

    await root!.runInTransactionAsync(
      TxMode.write,
      (store, storeName) {
        final tiles = root!.box<ObjectBoxTile>();

        final removeIds = <int>[];

        final query = (tiles.query()
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();
        tiles.putMany(
          query
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
        query.close();

        tiles.query(ObjectBoxTile_.id.oneOf(removeIds)).build()
          ..remove()
          ..close();
      },
      storeName,
    );
  }

  @override
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) async =>
      expectRoot
          .box<ObjectBoxStore>()
          .putAsync((await getStore(currentStoreName))..name = newStoreName);

  @override
  Future<void> deleteStore({
    required String storeName,
  }) async {
    // await resetStore(storeName: storeName);
    // might need to reset relations?

    final query = expectRoot
        .box<ObjectBoxStore>()
        .query(ObjectBoxStore_.name.equals(storeName))
        .build();
    await query.removeAsync();
    query.close();
  }

  @override
  Future<ObjectBoxTile?> readTile({
    required String url,
  }) async {
    final query = expectRoot
        .box<ObjectBoxTile>()
        .query(ObjectBoxTile_.url.equals(url))
        .build();
    final tile = await query.findUniqueAsync();
    query.close();
    return tile;
  }

  @override
  Future<void> createTile({
    required String url,
    required Uint8List bytes,
    required String storeName,
  }) async {
    expectRoot;

    await root!.runInTransactionAsync(
      TxMode.write,
      (store, args) {
        final tiles = root!.box<ObjectBoxTile>();

        final query = tiles.query(ObjectBoxTile_.url.equals(args.url)).build();

        tiles.put(
          (query.findUnique() ??
              ObjectBoxTile(
                url: args.url,
                lastModified: DateTime.now(),
                bytes: args.bytes,
              ))
            ..stores.add(ObjectBoxStore(name: args.storeName)),
        );

        query.close();
      },
      (url: url, bytes: bytes, storeName: storeName),
    );
  }

  @override
  Future<bool?> deleteTile({
    required String url,
    required String storeName,
  }) async {
    final tiles = expectRoot.box<ObjectBoxTile>();

    final query = (tiles.query(ObjectBoxTile_.url.equals(url))
          ..linkMany(
            ObjectBoxTile_.stores,
            ObjectBoxStore_.name.equals(storeName),
          ))
        .build();
    final tile = query.findUnique();
    if (tile == null) return null;

    tile.stores.removeWhere((store) => store.name == storeName);

    if (tile.stores.isEmpty) {
      await query.removeAsync();
      query.close();
      return true;
    }

    await tiles.putAsync(tile, mode: PutMode.update);
    query.close();
    return false;
  }
}
