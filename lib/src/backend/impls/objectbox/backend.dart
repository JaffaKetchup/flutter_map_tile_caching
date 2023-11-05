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

  @override
  String get friendlyIdentifier => 'ObjectBox';

  /// {@macro fmtc_backend_initialise}
  ///
  /// This implementation additionally accepts the following [implSpecificArgs]:
  ///
  ///  * 'macosApplicationGroup' (`String`): when creating a sandboxed macOS app,
  /// use to specify the application group (of less than 20 chars). See
  /// [the ObjectBox docs](https://docs.objectbox.io/getting-started) for
  /// details.
  ///  * 'maxReaders' (`int`): for debugging purposes only
  @override
  Future<void> initialise({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  }) async {
    final dir = await ((rootDirectory == null
                ? await getApplicationDocumentsDirectory()
                : Directory(rootDirectory)) >>
            'fmtc')
        .create(recursive: true);
    root = await openStore(
      directory: dir.absolute.path,
      maxDBSizeInKB: maxDatabaseSize,
      macosApplicationGroup:
          implSpecificArgs['macosApplicationGroup'] as String?,
      maxReaders: implSpecificArgs['maxReaders'] as int?,
    );
  }

  @override
  Future<void> destroy({
    bool deleteRoot = false,
  }) async {
    expectRoot;

    if (deleteRoot) {
      await Directory((root!..close()).directoryPath).delete(recursive: true);
    } else {
      root!.close();
    }
    root = null;
  }

  @override
  Future<void> createStore({
    required String storeName,
  }) async {
    await expectRoot.box<ObjectBoxStore>().putAsync(
          ObjectBoxStore(
            name: storeName,
            numberOfTiles: 0,
            numberOfBytes: 0,
          ),
          mode: PutMode.insert,
        );
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

        final tilesQuery = (tiles.query()
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();
        tiles.putMany(
          tilesQuery
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
        tilesQuery.close();

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
  }) async {
    final storeQuery = expectRoot
        .box<ObjectBoxStore>()
        .query(ObjectBoxStore_.name.equals(currentStoreName))
        .build();

    await root!.box<ObjectBoxStore>().putAsync(
          (await storeQuery.findUniqueAsync() ??
              (throw StoreUnavailable(storeName: currentStoreName)))
            ..name = newStoreName,
        );
  }

  @override
  Future<void> deleteStore({
    required String storeName,
  }) async {
    // await resetStore(storeName: storeName);
    // might need to reset relations?

    final storeQuery = expectRoot
        .box<ObjectBoxStore>()
        .query(ObjectBoxStore_.name.equals(storeName))
        .build();
    await storeQuery.removeAsync();
    storeQuery.close();
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
    required Uint8List? bytes,
    required String storeName,
  }) async {
    expectRoot;

    final tiles = root!.box<ObjectBoxTile>();
    final stores = root!.box<ObjectBoxStore>();

    final tilesQuery = tiles.query(ObjectBoxTile_.url.equals(url)).build();
    final existingTile = tilesQuery.findUnique();
    tilesQuery.close();

    final storeQuery =
        stores.query(ObjectBoxStore_.name.equals(storeName)).build();
    final store = storeQuery.findUnique() ??
        (throw StoreUnavailable(storeName: storeName));
    storeQuery.close();

    await root!.runInTransactionAsync(
      TxMode.write,
      (store, args) {
        final tiles = root!.box<ObjectBoxTile>();
        final stores = root!.box<ObjectBoxStore>();

        switch ((args.existingTile == null, args.bytes == null)) {
          case (true, false): // No existing tile
            tiles.put(
              ObjectBoxTile(
                url: args.url,
                lastModified: DateTime.now(),
                bytes: args.bytes!,
              )..stores.add(args.store),
            );
            stores.put(
              args.store
                ..numberOfTiles += 1
                ..numberOfBytes += args.bytes!.lengthInBytes,
            );
            break;
          case (false, true): // Existing tile, no update
            // Only take action if it's not already belonging to the store
            if (!args.existingTile!.stores.contains(args.store)) {
              tiles.put(args.existingTile!..stores.add(args.store));
              stores.put(
                args.store
                  ..numberOfTiles += 1
                  ..numberOfBytes += args.existingTile!.bytes.lengthInBytes,
              );
            }
            break;
          case (false, false): // Existing tile, update required
            tiles.put(
              args.existingTile!
                ..lastModified = DateTime.now()
                ..bytes = args.bytes!,
            );
            stores.putMany(
              args.existingTile!.stores
                  .map(
                    (store) => store
                      ..numberOfBytes += (args.bytes!.lengthInBytes -
                          args.existingTile!.bytes.lengthInBytes),
                  )
                  .toList(),
            );
            break;
          case (true, true): // FMTC internal error
            throw TileCannotUpdate(url: args.url);
        }
      },
      (url: url, bytes: bytes, existingTile: existingTile, store: store),
    );
  }

  @override
  Future<bool?> deleteTile({
    required String url,
    required String storeName,
  }) async {
    final tiles = expectRoot.box<ObjectBoxTile>();

    // Find the tile by URL
    final query = tiles.query(ObjectBoxTile_.url.equals(url)).build();
    final tile = query.findUnique();
    if (tile == null) return null;

    // For the correct store, adjust the statistics
    for (final store in tile.stores) {
      if (store.name != storeName) continue;
      store
        ..numberOfTiles -= 1
        ..numberOfBytes -= tile.bytes.lengthInBytes;
    }

    // Remove the store relation from the tile
    tile.stores.removeWhere((store) => store.name == storeName);

    // Delete the tile if it belongs to no stores
    if (tile.stores.isEmpty) {
      await query.removeAsync();
      query.close();
      return true;
    }

    // Otherwise just update the tile
    query.close();
    await tiles.putAsync(tile, mode: PutMode.update);
    return false;
  }
}
