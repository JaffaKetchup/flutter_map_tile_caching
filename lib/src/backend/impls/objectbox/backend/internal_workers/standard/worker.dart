// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../backend.dart';

Future<void> _worker(
  ({
    SendPort sendPort,
    String rootDirectory,
    int maxDatabaseSize,
    String? macosApplicationGroup,
    RootIsolateToken rootIsolateToken,
  }) input,
) async {
  //! SETUP !//

  // Setup comms
  final receivePort = ReceivePort();
  void sendRes({required int id, Map<String, dynamic>? data}) =>
      input.sendPort.send((id: id, data: data));

  // Enable ObjectBox usage from this background isolate
  BackgroundIsolateBinaryMessenger.ensureInitialized(input.rootIsolateToken);

  // Open database, kill self if failed
  late final Store root;
  try {
    // If already opened, attach existing instance
    // This can occur when a background `FlutterEngine` is in use, keeping the
    // database open
    if (Store.isOpen(input.rootDirectory)) {
      root = Store.attach(getObjectBoxModel(), input.rootDirectory);
    } else {
      root = await openStore(
        directory: input.rootDirectory,
        maxDBSizeInKB: input.maxDatabaseSize, // Defaults to 10 GB
        macosApplicationGroup: input.macosApplicationGroup,
      );
    }

    // If the database is new, create the root statistics object
    final rootBox = root.box<ObjectBoxRoot>();
    if (!rootBox.contains(1)) {
      rootBox.put(ObjectBoxRoot(length: 0, size: 0), mode: PutMode.insert);
    }
  } catch (e, s) {
    sendRes(id: 0, data: {'error': e, 'stackTrace': s});
    Isolate.exit();
  }

  // Create memory for streamed output subscription storage
  final streamedOutputSubscriptions = <int, StreamSubscription>{};

  // Respond with comms channel for future cmds
  sendRes(
    id: 0,
    data: {'sendPort': receivePort.sendPort},
  );

  //! UTIL METHODS !//

  /// Update the root statistics object (ID 0) with the existing values plus
  /// the specified values respectively
  ///
  /// Should be run within a transaction.
  ///
  /// Specified values may be negative.
  void updateRootStatistics({int deltaLength = 0, int deltaSize = 0}) =>
      root.box<ObjectBoxRoot>().put(
            root.box<ObjectBoxRoot>().get(1)!
              ..length += deltaLength
              ..size += deltaSize,
            mode: PutMode.update,
          );

  /// Delete the specified tiles from the specified store
  ///
  /// Note that [tilesQuery] is not closed internally. Ensure it is closed after
  /// usage.
  ///
  /// Note that a transaction is used internally as necessary.
  ///
  /// Returns the number of orphaned (deleted) tiles.
  Future<int> deleteTiles({
    required Query<ObjectBoxStore> storesQuery,
    required Query<ObjectBoxTile> tilesQuery,
  }) async {
    final stores = root.box<ObjectBoxStore>();
    final tiles = root.box<ObjectBoxTile>();

    bool hadTilesToUpdate = false;
    int rootDeltaSize = 0;
    final tilesToRemove = <int>[];
    final storesToUpdate = <String, ObjectBoxStore>{};

    final queriedStores = storesQuery.property(ObjectBoxStore_.name).find();
    if (queriedStores.isEmpty) return 0;

    // For each store, remove it from the tile if requested
    // For each store & if removed, update that store's stats
    await for (final tile in tilesQuery.stream()) {
      tile.stores.removeWhere((store) {
        if (!queriedStores.contains(store.name)) return false;

        storesToUpdate[store.name] = (storesToUpdate[store.name] ?? store)
          ..length -= 1
          ..size -= tile.bytes.lengthInBytes;

        return true;
      });

      if (tile.stores.isNotEmpty) {
        tile.stores.applyToDb(mode: PutMode.update);
        hadTilesToUpdate = true;
        continue;
      }

      rootDeltaSize -= tile.bytes.lengthInBytes;
      tilesToRemove.add(tile.id);
    }

    if (!hadTilesToUpdate && tilesToRemove.isEmpty) return 0;

    root.runInTransaction(
      TxMode.write,
      () {
        tilesToRemove.forEach(tiles.remove);

        updateRootStatistics(
          deltaLength: -tilesToRemove.length,
          deltaSize: rootDeltaSize,
        );

        stores.putMany(
          storesToUpdate.values.toList(),
          mode: PutMode.update,
        );
      },
    );

    return tilesToRemove.length;
  }

  /// Verify that the specified file is a valid FMTC format archive, compatible
  /// with this ObjectBox backend
  ///
  /// Note that this method writes to the input file, converting it to a valid
  /// database if possible
  void verifyImportableArchive(File importFile) {
    final ram = importFile.openSync(mode: FileMode.append);
    try {
      int cursorPos = ram.positionSync() - 1;
      ram.setPositionSync(cursorPos);

      // Check for FMTC footer signature ("**FMTC")
      const signature = [255, 255, 70, 77, 84, 67];
      for (int i = 5; i >= 0; i--) {
        if (signature[i] != ram.readByteSync()) {
          throw ImportFileNotFMTCStandard();
        }
        ram.setPositionSync(--cursorPos);
      }

      // Check for expected backend identifier ("**ObjectBox")
      const id = [255, 255, 79, 98, 106, 101, 99, 116, 66, 111, 120];
      for (int i = 10; i >= 0; i--) {
        if (id[i] != ram.readByteSync()) {
          throw ImportFileNotBackendCompatible();
        }
        ram.setPositionSync(--cursorPos);
      }

      ram.truncateSync(--cursorPos);
    } catch (e) {
      ram.closeSync();
      rethrow;
    }
    ram.closeSync();
  }

  //! MAIN HANDLER !//

  void mainHandler(_IncomingCmd cmd) {
    switch (cmd.type) {
      case _CmdType.initialise_:
        throw UnsupportedError('Invalid operation');
      case _CmdType.destroy:
        root.close();

        if (cmd.args['deleteRoot'] == true) {
          if (input.rootDirectory.startsWith(Store.inMemoryPrefix)) {
            Store.removeDbFiles(input.rootDirectory);
          } else {
            Directory(input.rootDirectory).deleteSync(recursive: true);
          }
        }

        sendRes(id: cmd.id);

        Isolate.exit();
      case _CmdType.realSize:
        sendRes(
          id: cmd.id,
          data: {
            'size':
                Store.dbFileSize(input.rootDirectory) / 1024, // Convert to KiB
          },
        );
      case _CmdType.rootSize:
        sendRes(
          id: cmd.id,
          data: {'size': root.box<ObjectBoxRoot>().get(1)!.size / 1024},
        );
      case _CmdType.rootLength:
        sendRes(
          id: cmd.id,
          data: {'length': root.box<ObjectBoxRoot>().get(1)!.length},
        );
      case _CmdType.listStores:
        final query = root
            .box<ObjectBoxStore>()
            .query()
            .build()
            .property(ObjectBoxStore_.name);

        sendRes(id: cmd.id, data: {'stores': query.find()});

        query.close();
      case _CmdType.storeExists:
        final query = root
            .box<ObjectBoxStore>()
            .query(
              ObjectBoxStore_.name.equals(cmd.args['storeName']! as String),
            )
            .build();

        sendRes(id: cmd.id, data: {'exists': query.count() == 1});

        query.close();
      case _CmdType.getStoreStats:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();

        final store =
            query.findUnique() ?? (throw StoreNotExists(storeName: storeName));

        sendRes(
          id: cmd.id,
          data: {
            'stats': (
              size: store.size / 1024, // Convert to KiB
              length: store.length,
              hits: store.hits,
              misses: store.misses,
            ),
          },
        );

        query.close();
      case _CmdType.storeGetMaxLength:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();

        sendRes(
          id: cmd.id,
          data: {
            'maxLength': (query.findUnique() ??
                    (throw StoreNotExists(storeName: storeName)))
                .maxLength,
          },
        );

        query.close();
      case _CmdType.storeSetMaxLength:
        final storeName = cmd.args['storeName']! as String;
        final newMaxLength = cmd.args['newMaxLength'] as int?;

        final stores = root.box<ObjectBoxStore>();

        final query =
            stores.query(ObjectBoxStore_.name.equals(storeName)).build();

        root.runInTransaction(
          TxMode.write,
          () {
            final store = query.findUnique() ??
                (throw StoreNotExists(storeName: storeName));
            query.close();

            stores.put(store..maxLength = newMaxLength, mode: PutMode.update);
          },
        );

        sendRes(id: cmd.id);
      case _CmdType.createStore:
        final storeName = cmd.args['storeName']! as String;
        final maxLength = cmd.args['maxLength'] as int?;

        try {
          root.box<ObjectBoxStore>().put(
                ObjectBoxStore(
                  name: storeName,
                  maxLength: maxLength,
                  length: 0,
                  size: 0,
                  hits: 0,
                  misses: 0,
                  metadataJson: '{}',
                ),
                mode: PutMode.insert,
              );
        } on UniqueViolationException {
          sendRes(id: cmd.id);
          break;
        }

        sendRes(id: cmd.id);
      case _CmdType.resetStore:
        final storeName = cmd.args['storeName']! as String;

        final tiles = root.box<ObjectBoxTile>();
        final stores = root.box<ObjectBoxStore>();

        final storeQuery =
            stores.query(ObjectBoxStore_.name.equals(storeName)).build();

        final store = storeQuery.findUnique() ??
            (throw StoreNotExists(storeName: storeName));

        final tilesQuery = (tiles.query()
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();

        deleteTiles(storesQuery: storeQuery, tilesQuery: tilesQuery).then((_) {
          stores.put(
            store
              ..length = 0
              ..size = 0
              ..hits = 0
              ..misses = 0,
            mode: PutMode.update,
          );

          sendRes(id: cmd.id);

          storeQuery.close();
          tilesQuery.close();
        });
      case _CmdType.renameStore:
        final currentStoreName = cmd.args['currentStoreName']! as String;
        final newStoreName = cmd.args['newStoreName']! as String;

        final stores = root.box<ObjectBoxStore>();

        final query =
            stores.query(ObjectBoxStore_.name.equals(currentStoreName)).build();

        root.runInTransaction(
          TxMode.write,
          () {
            final store = query.findUnique() ??
                (throw StoreNotExists(storeName: currentStoreName));
            query.close();

            stores.put(store..name = newStoreName, mode: PutMode.update);
          },
        );

        sendRes(id: cmd.id);
      case _CmdType.deleteStore:
        final storeName = cmd.args['storeName']! as String;

        final storesQuery = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final tilesQuery = (root.box<ObjectBoxTile>().query()
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();

        deleteTiles(storesQuery: storesQuery, tilesQuery: tilesQuery).then((_) {
          storesQuery.remove();

          sendRes(id: cmd.id);

          storesQuery.close();
          tilesQuery.close();
        });
      case _CmdType.tileExists:
        final url = cmd.args['url']! as String;
        final storeNames = cmd.args['storeNames']! as List<String>?;

        final stores = root.box<ObjectBoxTile>();

        final queryPart = stores.query(ObjectBoxTile_.url.equals(url));
        final query = storeNames == null
            ? queryPart.build()
            : (queryPart
                  ..linkMany(
                    ObjectBoxTile_.stores,
                    ObjectBoxStore_.name.oneOf(storeNames),
                  ))
                .build();

        sendRes(id: cmd.id, data: {'exists': query.count() == 1});

        query.close();
      case _CmdType.readTile:
        final url = cmd.args['url']! as String;
        final storeNames = cmd.args['storeNames'] as List<String>?;

        final stores = root.box<ObjectBoxTile>();
        final specifiedStores = storeNames?.isNotEmpty ?? false;

        final queryPart = stores.query(ObjectBoxTile_.url.equals(url));
        final query = !specifiedStores
            ? queryPart.build()
            : (queryPart
                  ..linkMany(
                    ObjectBoxTile_.stores,
                    ObjectBoxStore_.name.oneOf(storeNames!),
                  ))
                .build();

        final tile = query.findUnique();
        query.close();

        if (tile == null) {
          sendRes(
            id: cmd.id,
            data: {
              'tile': null,
              'allStoreNames': const <String>[],
              'intersectedStoreNames': const <String>[],
            },
          );
        } else {
          final tileStores = tile.stores.map((s) => s.name);
          final listTileStores = tileStores.toList(growable: false);

          sendRes(
            id: cmd.id,
            data: {
              'tile': tile,
              'allStoreNames': listTileStores,
              'intersectedStoreNames': !specifiedStores
                  ? listTileStores
                  : SplayTreeSet<String>.from(tileStores)
                      .intersection(SplayTreeSet<String>.from(storeNames!))
                      .toList(growable: false),
            },
          );
        }
      case _CmdType.readLatestTile:
        final storeName = cmd.args['storeName']! as String;

        final query = (root
                .box<ObjectBoxTile>()
                .query()
                .order(ObjectBoxTile_.lastModified, flags: Order.descending)
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();

        sendRes(id: cmd.id, data: {'tile': query.findFirst()});

        query.close();
      case _CmdType.writeTile:
        final storeNames = cmd.args['storeNames']! as List<String>;
        final writeAllNotIn = cmd.args['writeAllNotIn'] as List<String>?;
        final url = cmd.args['url']! as String;
        final bytes = cmd.args['bytes']! as Uint8List;

        final result = _sharedWriteSingleTile(
          root: root,
          storeNames: storeNames,
          writeAllNotIn: writeAllNotIn,
          url: url,
          bytes: bytes,
        );

        sendRes(id: cmd.id, data: {'result': result});
      case _CmdType.deleteTile:
        final storeName = cmd.args['storeName']! as String;
        final url = cmd.args['url']! as String;

        final storesQuery = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final tilesQuery = root
            .box<ObjectBoxTile>()
            .query(ObjectBoxTile_.url.equals(url))
            .build();

        deleteTiles(storesQuery: storesQuery, tilesQuery: tilesQuery)
            .then((orphans) {
          sendRes(
            id: cmd.id,
            data: {'wasOrphan': orphans == 1},
          );

          storesQuery.close();
          tilesQuery.close();
        });
      case _CmdType.registerHitOrMiss:
        final storeNames = cmd.args['storeNames'] as List<String>?;
        final hit = cmd.args['hit']! as bool;

        final storesBox = root.box<ObjectBoxStore>();
        final specifiedStores = storeNames?.isNotEmpty ?? false;

        late final Query<ObjectBoxStore> query;
        if (specifiedStores) {
          query =
              storesBox.query(ObjectBoxStore_.name.oneOf(storeNames!)).build();
        }

        root.runInTransaction(
          TxMode.write,
          () {
            final stores = specifiedStores ? query.find() : storesBox.getAll();
            if (specifiedStores) {
              if (stores.length != storeNames!.length) {
                return StoreNotExists(
                  storeName:
                      storeNames.toSet().difference(stores.toSet()).join('; '),
                );
              }

              query.close();
            }

            for (final store in stores) {
              storesBox.put(
                store
                  ..hits += hit ? 1 : 0
                  ..misses += hit ? 0 : 1,
              );
            }
          },
        );

        sendRes(id: cmd.id);
      case _CmdType.removeOldestTilesAboveLimit:
        final storeNames = cmd.args['storeNames']! as List<String>;

        final tilesQuery = (root
                .box<ObjectBoxTile>()
                .query()
                .order(ObjectBoxTile_.lastModified)
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(''),
              ))
            .build();

        final storeQuery = root
            .box<ObjectBoxStore>()
            .query(
              ObjectBoxStore_.name
                  .equals('')
                  .and(ObjectBoxStore_.maxLength.notNull()),
            )
            .build();

        Future.wait(
          storeNames.map(
            (storeName) async {
              tilesQuery.param(ObjectBoxStore_.name).value = storeName;
              storeQuery.param(ObjectBoxStore_.name).value = storeName;

              final store = storeQuery.findUnique();
              if (store == null) return 0;

              final numToRemove = store.length - store.maxLength!;
              if (numToRemove <= 0) return 0;

              tilesQuery.limit = numToRemove;

              return deleteTiles(
                storesQuery: storeQuery,
                tilesQuery: tilesQuery,
              );
            },
          ),
        ).then(
          (numOrphans) {
            sendRes(
              id: cmd.id,
              data: {'numOrphans': Map.fromIterables(storeNames, numOrphans)},
            );

            storeQuery.close();
            tilesQuery.close();
          },
        );
      case _CmdType.removeTilesOlderThan:
        final storeName = cmd.args['storeName']! as String;
        final expiry = cmd.args['expiry']! as DateTime;

        final storesQuery = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();
        final tilesQuery = (root.box<ObjectBoxTile>().query(
                  ObjectBoxTile_.lastModified
                      .greaterThan(expiry.millisecondsSinceEpoch),
                )..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.equals(storeName),
              ))
            .build();

        deleteTiles(storesQuery: storesQuery, tilesQuery: tilesQuery)
            .then((orphans) {
          sendRes(
            id: cmd.id,
            data: {'numOrphans': orphans},
          );

          storesQuery.close();
          tilesQuery.close();
        });

      case _CmdType.readMetadata:
        final storeName = cmd.args['storeName']! as String;

        final query = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(storeName))
            .build();

        final store =
            query.findUnique() ?? (throw StoreNotExists(storeName: storeName));

        sendRes(
          id: cmd.id,
          data: {
            'metadata': (jsonDecode(store.metadataJson) as Map<String, dynamic>)
                .cast<String, String>(),
          },
        );

        query.close();
      case _CmdType.setBulkMetadata:
        final storeName = cmd.args['storeName']! as String;
        final kvs = cmd.args['kvs']! as Map<String, String>;

        final stores = root.box<ObjectBoxStore>();

        final query =
            stores.query(ObjectBoxStore_.name.equals(storeName)).build();

        root.runInTransaction(
          TxMode.write,
          () {
            final store = query.findUnique() ??
                (throw StoreNotExists(storeName: storeName));
            query.close();

            stores.put(
              store
                ..metadataJson = jsonEncode(
                  (jsonDecode(store.metadataJson) as Map<String, dynamic>)
                    ..addAll(kvs),
                ),
              mode: PutMode.update,
            );
          },
        );

        sendRes(id: cmd.id);
      case _CmdType.removeMetadata:
        final storeName = cmd.args['storeName']! as String;
        final key = cmd.args['key']! as String;

        final stores = root.box<ObjectBoxStore>();

        final query =
            stores.query(ObjectBoxStore_.name.equals(storeName)).build();

        sendRes(
          id: cmd.id,
          data: {
            'removedValue': root.runInTransaction(
              TxMode.write,
              () {
                final store = query.findUnique() ??
                    (throw StoreNotExists(storeName: storeName));
                query.close();

                final metadata =
                    jsonDecode(store.metadataJson) as Map<String, dynamic>;
                final removedVal = metadata.remove(key) as String?;

                stores.put(
                  store..metadataJson = jsonEncode(metadata),
                  mode: PutMode.update,
                );

                return removedVal;
              },
            ),
          },
        );
      case _CmdType.resetMetadata:
        final storeName = cmd.args['storeName']! as String;

        final stores = root.box<ObjectBoxStore>();

        final query =
            stores.query(ObjectBoxStore_.name.equals(storeName)).build();

        root.runInTransaction(
          TxMode.write,
          () {
            final store = query.findUnique() ??
                (throw StoreNotExists(storeName: storeName));
            query.close();

            stores.put(
              store..metadataJson = '{}',
              mode: PutMode.update,
            );
          },
        );

        sendRes(id: cmd.id);
      case _CmdType.listRecoverableRegions:
        sendRes(
          id: cmd.id,
          data: {
            'recoverableRegions': root
                .box<ObjectBoxRecovery>()
                .getAll()
                .map((r) => r.toRegion())
                .toList(growable: false),
          },
        );
      case _CmdType.getRecoverableRegion:
        final id = cmd.args['id']! as int;

        sendRes(
          id: cmd.id,
          data: {
            'recoverableRegion': (root
                    .box<ObjectBoxRecovery>()
                    .query(ObjectBoxRecovery_.refId.equals(id))
                    .build()
                  ..close())
                .findUnique()
                ?.toRegion(),
          },
        );
      case _CmdType.cancelRecovery:
        final id = cmd.args['id']! as int;

        root
            .box<ObjectBoxRecovery>()
            .query(ObjectBoxRecovery_.refId.equals(id))
            .build()
          ..remove()
          ..close();

        sendRes(id: cmd.id);
      case _CmdType.watchRecovery:
        final triggerImmediately = cmd.args['triggerImmediately']! as bool;

        streamedOutputSubscriptions[cmd.id] = root
            .box<ObjectBoxRecovery>()
            .query()
            .watch(triggerImmediately: triggerImmediately)
            .listen((_) => sendRes(id: cmd.id, data: {'expectStream': true}));
      case _CmdType.watchStores:
        final storeNames = cmd.args['storeNames']! as List<String>;
        final triggerImmediately = cmd.args['triggerImmediately']! as bool;

        streamedOutputSubscriptions[cmd.id] = root
            .box<ObjectBoxStore>()
            .query(
              storeNames.isEmpty
                  ? null
                  : ObjectBoxStore_.name.oneOf(storeNames),
            )
            .watch(triggerImmediately: triggerImmediately)
            .listen((_) => sendRes(id: cmd.id, data: {'expectStream': true}));
      case _CmdType.cancelInternalStreamSub:
        final id = cmd.args['id']! as int;

        if (streamedOutputSubscriptions[id] == null) {
          throw StateError(
            'Cannot cancel internal streamed result because none was registered.',
          );
        }

        streamedOutputSubscriptions[id]!.cancel();
        streamedOutputSubscriptions.remove(id);

        sendRes(id: cmd.id);
      case _CmdType.exportStores:
        final storeNames = cmd.args['storeNames']! as List<String>;
        final outputPath = cmd.args['outputPath']! as String;

        final outputDir = path.dirname(outputPath);

        if (path.equals(outputDir, input.rootDirectory)) {
          throw ExportInRootDirectoryForbidden();
        }

        Directory(outputDir).createSync(recursive: true);

        final exportingRoot = Store(
          getObjectBoxModel(),
          directory: outputDir,
          maxDBSizeInKB: input.maxDatabaseSize, // Defaults to 10 GB
          macosApplicationGroup: input.macosApplicationGroup,
        );

        final storesQuery = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.oneOf(storeNames))
            .build();

        final tilesQuery = (root.box<ObjectBoxTile>().query()
              ..linkMany(
                ObjectBoxTile_.stores,
                ObjectBoxStore_.name.oneOf(storeNames),
              ))
            .build();

        final storesObjectsForRelations = <String, ObjectBoxStore>{};

        final exportingStores = root.runInTransaction(
          TxMode.read,
          storesQuery.stream,
        );

        exportingRoot
            .runInTransaction(
              TxMode.write,
              () => exportingStores.map(
                (exportingStore) {
                  exportingRoot.box<ObjectBoxStore>().put(
                        storesObjectsForRelations[exportingStore.name] =
                            ObjectBoxStore(
                          name: exportingStore.name,
                          maxLength: exportingStore.maxLength,
                          length: exportingStore.length,
                          size: exportingStore.size,
                          hits: exportingStore.hits,
                          misses: exportingStore.misses,
                          metadataJson: exportingStore.metadataJson,
                        ),
                        mode: PutMode.insert,
                      );
                },
              ),
            )
            .length
            .then(
          (numExportedStores) {
            if (numExportedStores == 0) throw StateError('Unpossible.');

            final exportingTiles = root.runInTransaction(
              TxMode.read,
              tilesQuery.stream,
            );

            exportingRoot
                .runInTransaction(
                  TxMode.write,
                  () => exportingTiles.map(
                    (exportingTile) {
                      exportingRoot.box<ObjectBoxTile>().put(
                            ObjectBoxTile(
                              url: exportingTile.url,
                              bytes: exportingTile.bytes,
                              lastModified: exportingTile.lastModified,
                            )..stores.addAll(
                                exportingTile.stores
                                    .map(
                                      (s) => storesObjectsForRelations[s.name],
                                    )
                                    .whereNotNull(),
                              ),
                            mode: PutMode.insert,
                          );
                    },
                  ),
                )
                .length
                .then(
              (numExportedTiles) {
                if (numExportedTiles == 0) {
                  throw ArgumentError(
                    'Specified stores must include at least one tile total',
                    'storeNames',
                  );
                }

                storesQuery.close();
                tilesQuery.close();
                exportingRoot.close();

                File(path.join(outputDir, 'lock.mdb')).delete();

                final ram = File(path.join(outputDir, 'data.mdb'))
                    .renameSync(outputPath)
                    .openSync(mode: FileMode.writeOnlyAppend);
                try {
                  ram
                    ..writeFromSync(List.filled(4, 255))
                    ..writeStringSync('ObjectBox') // Backend identifier
                    ..writeByteSync(255)
                    ..writeByteSync(255)
                    ..writeStringSync('FMTC'); // Signature
                } finally {
                  ram.closeSync();
                }

                sendRes(id: cmd.id);
              },
            );
          },
        );
      case _CmdType.importStores:
        final importPath = cmd.args['path']! as String;
        final strategy = cmd.args['strategy'] as ImportConflictStrategy;
        final storesToImport = cmd.args['stores'] as List<String>?;

        final importDir = path.join(input.rootDirectory, 'import_tmp');
        final importDirIO = Directory(importDir)..createSync();

        final importFile =
            File(importPath).copySync(path.join(importDir, 'data.mdb'));

        try {
          verifyImportableArchive(importFile);
        } catch (e) {
          importFile.deleteSync();
          importDirIO.deleteSync();
          rethrow;
        }

        final importingRoot = Store(
          getObjectBoxModel(),
          directory: importDir,
          maxDBSizeInKB: input.maxDatabaseSize,
          macosApplicationGroup: input.macosApplicationGroup,
        );

        final importingStoresQuery = importingRoot
            .box<ObjectBoxStore>()
            .query(
              (storesToImport?.isEmpty ?? true)
                  ? null
                  : ObjectBoxStore_.name.oneOf(storesToImport!),
            )
            .build();
        final specificStoresQuery = root
            .box<ObjectBoxStore>()
            .query(ObjectBoxStore_.name.equals(''))
            .build();

        void cleanup() {
          importingStoresQuery.close();
          specificStoresQuery.close();
          importingRoot.close();

          importFile.deleteSync();
          File(path.join(importDir, 'lock.mdb')).deleteSync();
          importDirIO.deleteSync();
        }

        final StoresToStates storesToStates = {};
        // ignore: unnecessary_parenthesis
        (switch (strategy) {
          ImportConflictStrategy.skip => importingStoresQuery
              .stream()
              .where(
                (importingStore) {
                  final name = importingStore.name;
                  final hasConflict = (specificStoresQuery
                            ..param(ObjectBoxStore_.name).value = name)
                          .count() ==
                      1;
                  storesToStates[name] = (
                    name: hasConflict ? null : name,
                    hadConflict: hasConflict,
                  );

                  if (hasConflict) return false;

                  root.box<ObjectBoxStore>().put(
                        ObjectBoxStore(
                          name: name,
                          maxLength: importingStore.maxLength,
                          length: importingStore.length,
                          size: importingStore.size,
                          hits: 0,
                          misses: 0,
                          metadataJson: importingStore.metadataJson,
                        ),
                        mode: PutMode.insert,
                      );
                  return true;
                },
              )
              .map((s) => s.name)
              .toList(),
          ImportConflictStrategy.rename =>
            importingStoresQuery.stream().map((importingStore) {
              final name = importingStore.name;

              if ((specificStoresQuery
                        ..param(ObjectBoxStore_.name).value = name)
                      .count() ==
                  0) {
                storesToStates[name] = (name: name, hadConflict: false);
                root.box<ObjectBoxStore>().put(
                      ObjectBoxStore(
                        name: name,
                        maxLength: importingStore.maxLength,
                        length: importingStore.length,
                        size: importingStore.size,
                        hits: 0,
                        misses: 0,
                        metadataJson: importingStore.metadataJson,
                      ),
                      mode: PutMode.insert,
                    );
                return name;
              } else {
                final newName = '$name [Imported ${DateTime.now()}]';
                storesToStates[name] = (name: newName, hadConflict: true);
                final newStore = importingStore..name = newName;
                importingRoot
                    .box<ObjectBoxStore>()
                    .put(newStore, mode: PutMode.update);
                root.box<ObjectBoxStore>().put(
                      ObjectBoxStore(
                        name: newName,
                        maxLength: importingStore.maxLength,
                        length: importingStore.length,
                        size: importingStore.size,
                        hits: 0,
                        misses: 0,
                        metadataJson: importingStore.metadataJson,
                      ),
                      mode: PutMode.insert,
                    );
                return newName;
              }
            }).toList(),
          ImportConflictStrategy.replace ||
          ImportConflictStrategy.merge =>
            importingStoresQuery.stream().map(
              (importingStore) {
                final name = importingStore.name;

                final existingStore = (specificStoresQuery
                      ..param(ObjectBoxStore_.name).value = name)
                    .findUnique();
                if (existingStore == null) {
                  storesToStates[name] = (name: name, hadConflict: false);
                  root.box<ObjectBoxStore>().put(
                        ObjectBoxStore(
                          name: name,
                          maxLength: importingStore.maxLength,
                          length: 0, // Will be set when writing tiles
                          size: 0, // Will be set when writing tiles
                          hits: 0,
                          misses: 0,
                          metadataJson: importingStore.metadataJson,
                        ),
                        mode: PutMode.insert,
                      );
                } else {
                  storesToStates[name] = (name: name, hadConflict: true);
                  if (strategy == ImportConflictStrategy.merge) {
                    root.box<ObjectBoxStore>().put(
                          existingStore
                            ..maxLength = importingStore.maxLength
                            ..metadataJson = jsonEncode(
                              (jsonDecode(existingStore.metadataJson)
                                  as Map<String, dynamic>)
                                ..addAll(
                                  jsonDecode(importingStore.metadataJson)
                                      as Map<String, dynamic>,
                                ),
                            ),
                          mode: PutMode.update,
                        );
                  }
                }

                return name;
              },
            ).toList(),
        })
            .then(
          (storesToImport) async {
            sendRes(
              id: cmd.id,
              data: {
                'expectStream': true,
                'storesToStates': storesToStates,
                if (storesToImport.isEmpty) 'complete': 0,
              },
            );
            if (storesToImport.isEmpty) {
              cleanup();
              return;
            }

            // At this point:
            //  * storesToImport should contain only the required IMPORT stores
            //  * root's stores should be set so that every import store has an
            //    equivalent with the same name
            // It is important never to 'copy' from the import root to the
            // in-use root

            final importingTilesQuery =
                (importingRoot.box<ObjectBoxTile>().query()
                      ..linkMany(
                        ObjectBoxTile_.stores,
                        ObjectBoxStore_.name.oneOf(storesToImport),
                      ))
                    .build();
            final importingTiles = importingTilesQuery.stream();

            final existingStoresQuery = root
                .box<ObjectBoxStore>()
                .query(ObjectBoxStore_.name.equals(''))
                .build();
            final existingTilesQuery = root
                .box<ObjectBoxTile>()
                .query(ObjectBoxTile_.url.equals(''))
                .build();

            final storesToUpdate = <String, ObjectBoxStore>{};

            int rootDeltaLength = 0;
            int rootDeltaSize = 0;

            Iterable<ObjectBoxStore> convertToExistingStores(
              Iterable<ObjectBoxStore> importingStores,
            ) =>
                importingStores
                    .where((s) => storesToImport.contains(s.name))
                    .map(
                      (s) => storesToUpdate[s.name] ??= (existingStoresQuery
                            ..param(ObjectBoxStore_.name).value = s.name)
                          .findUnique()!,
                    );

            if (strategy == ImportConflictStrategy.replace) {
              final storesQuery = root
                  .box<ObjectBoxStore>()
                  .query(ObjectBoxStore_.name.oneOf(storesToImport))
                  .build();
              final tilesQuery = (root.box<ObjectBoxTile>().query()
                    ..linkMany(
                      ObjectBoxTile_.stores,
                      ObjectBoxStore_.name.oneOf(storesToImport),
                    ))
                  .build();

              await deleteTiles(
                storesQuery: storesQuery,
                tilesQuery: tilesQuery,
              );

              final importingStoresQuery = importingRoot
                  .box<ObjectBoxStore>()
                  .query(ObjectBoxStore_.name.oneOf(storesToImport))
                  .build();

              final importingStores = importingStoresQuery.find();

              storesQuery.remove();

              root.box<ObjectBoxStore>().putMany(
                    List.generate(
                      importingStores.length,
                      (i) => ObjectBoxStore(
                        name: importingStores[i].name,
                        maxLength: importingStores[i].maxLength,
                        length: importingStores[i].length,
                        size: importingStores[i].size,
                        hits: importingStores[i].hits,
                        misses: importingStores[i].misses,
                        metadataJson: importingStores[i].metadataJson,
                      ),
                      growable: false,
                    ),
                    mode: PutMode.insert,
                  );

              storesQuery.close();
              tilesQuery.close();
              importingStoresQuery.close();
            }

            final numImportedTiles = await root
                .runInTransaction(
                  TxMode.write,
                  () => importingTiles.map((importingTile) {
                    final convertedRelatedStores =
                        convertToExistingStores(importingTile.stores);

                    final existingTile = (existingTilesQuery
                          ..param(ObjectBoxTile_.url).value = importingTile.url)
                        .findUnique();

                    if (existingTile == null) {
                      root.box<ObjectBoxTile>().put(
                            ObjectBoxTile(
                              url: importingTile.url,
                              bytes: importingTile.bytes,
                              lastModified: importingTile.lastModified,
                            )..stores.addAll(convertedRelatedStores),
                            mode: PutMode.insert,
                          );

                      // No need to modify store stats, because if tile didn't
                      // already exist, then was not present in an existing
                      // store that needs changing, and all importing stores
                      // are brand new and already contain accurate stats.
                      // EXCEPT in merge mode - importing stores may not be
                      // new.
                      if (strategy == ImportConflictStrategy.merge) {
                        // No need to worry if it was brand new, we use the
                        // same logic, treating it as an existing related
                        // store, because when we created it, we made it
                        // empty.
                        for (final convertedRelatedStore
                            in convertedRelatedStores) {
                          storesToUpdate[convertedRelatedStore.name] =
                              (storesToUpdate[convertedRelatedStore.name] ??
                                  convertedRelatedStore)
                                ..length += 1
                                ..size += importingTile.bytes.lengthInBytes;
                        }
                      }

                      rootDeltaLength++;
                      rootDeltaSize += importingTile.bytes.lengthInBytes;

                      return 1;
                    }

                    final existingTileIsNewer = existingTile.lastModified
                            .isAfter(importingTile.lastModified) ||
                        existingTile.lastModified == importingTile.lastModified;

                    final relations = {
                      ...existingTile.stores,
                      ...convertedRelatedStores,
                    };

                    root.box<ObjectBoxTile>().put(
                          ObjectBoxTile(
                            url: importingTile.url,
                            bytes: existingTileIsNewer
                                ? existingTile.bytes
                                : importingTile.bytes,
                            lastModified: existingTileIsNewer
                                ? existingTile.lastModified
                                : importingTile.lastModified,
                          )..stores.addAll(relations),
                        );

                    if (strategy == ImportConflictStrategy.merge) {
                      for (final newConvertedRelatedStore
                          in convertedRelatedStores) {
                        if (existingTile.stores
                            .map((e) => e.name)
                            .contains(newConvertedRelatedStore.name)) {
                          continue;
                        }

                        storesToUpdate[newConvertedRelatedStore.name] =
                            (storesToUpdate[newConvertedRelatedStore.name] ??
                                newConvertedRelatedStore)
                              ..length += 1
                              ..size += (existingTileIsNewer
                                      ? existingTile
                                      : importingTile)
                                  .bytes
                                  .lengthInBytes;
                      }
                    }

                    if (existingTileIsNewer) return null;

                    for (final existingTileStore in existingTile.stores) {
                      storesToUpdate[existingTileStore.name] =
                          (storesToUpdate[existingTileStore.name] ??
                              existingTileStore)
                            ..size += -existingTile.bytes.lengthInBytes +
                                importingTile.bytes.lengthInBytes;
                    }

                    rootDeltaSize += -existingTile.bytes.lengthInBytes +
                        importingTile.bytes.lengthInBytes;

                    return 1;
                  }),
                )
                .where((e) => e != null)
                .length;

            root.box<ObjectBoxStore>().putMany(
                  storesToUpdate.values.toList(),
                  mode: PutMode.update,
                );

            updateRootStatistics(
              deltaLength: rootDeltaLength,
              deltaSize: rootDeltaSize,
            );

            importingTilesQuery.close();
            existingStoresQuery.close();
            existingTilesQuery.close();
            cleanup();

            sendRes(
              id: cmd.id,
              data: {
                'expectStream': true,
                'complete': numImportedTiles,
              },
            );
          },
        );
      case _CmdType.listImportableStores:
        final importPath = cmd.args['path']! as String;

        final importDir = path.join(input.rootDirectory, 'import_tmp');
        final importDirIO = Directory(importDir)..createSync();

        final importFile =
            File(importPath).copySync(path.join(importDir, 'data.mdb'));

        try {
          verifyImportableArchive(importFile);
        } catch (e) {
          importFile.deleteSync();
          importDirIO.deleteSync();
          rethrow;
        }

        final importingRoot = Store(
          getObjectBoxModel(),
          directory: importDir,
          maxDBSizeInKB: input.maxDatabaseSize, // Defaults to 10 GB
          macosApplicationGroup: input.macosApplicationGroup,
        );

        sendRes(
          id: cmd.id,
          data: {
            'stores': importingRoot
                .box<ObjectBoxStore>()
                .getAll()
                .map((e) => e.name)
                .toList(growable: false),
          },
        );

        importingRoot.close();

        importFile.deleteSync();
        File(path.join(importDir, 'lock.mdb')).deleteSync();
        importDirIO.deleteSync();
    }
  }

  //! CMD/COMM RECIEVER !//

  await receivePort.listen((cmd) {
    try {
      mainHandler(cmd);
    } catch (e, s) {
      cmd as _IncomingCmd;

      sendRes(
        id: cmd.id,
        data: {
          if (cmd.type.hasInternalStreamSub != null) 'expectStream': true,
          'error': e,
          'stackTrace': s,
        },
      );
    }
  }).asFuture<void>();
}
