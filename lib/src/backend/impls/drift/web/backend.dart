// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/wasm.dart';

import '../../../../../flutter_map_tile_caching.dart';
import '../../../export_internal.dart';
import '../native/backend/models/drift_backend_tile.dart';
import '../native/backend/utils/region_serialization.dart';
import '../native/database/database.dart';
import '../native/database/models/recovery.drift.dart';
import '../native/database/models/root.drift.dart';
import '../native/database/models/store.drift.dart';
import '../native/database/models/store_tile.drift.dart'
    show DriftStoreTileCompanion;
import '../native/database/models/tile.drift.dart';

/// Implementation of [FMTCBackend] that uses Drift (SQLite via WASM) on web
final class FMTCDriftBackend implements FMTCBackend {
  /// {@macro fmtc.backend.initialise}
  @override
  Future<void> initialise({
    String? rootDirectory,
    @visibleForTesting bool useInMemoryDatabase = false,
  }) =>
      FMTCDriftBackendInternal._instance.initialise(
        useInMemoryDatabase: useInMemoryDatabase,
      );

  /// {@macro fmtc.backend.uninitialise}
  @override
  Future<void> uninitialise({
    bool deleteRoot = false,
  }) =>
      FMTCDriftBackendInternal._instance.uninitialise(deleteRoot: deleteRoot);
}

/// Internal implementation of [FMTCBackend] for web using Drift (WASM)
abstract interface class FMTCDriftBackendInternal
    implements FMTCBackendInternal {
  static final _instance = _FMTCDriftBackendInternalWeb._();
}

class _FMTCDriftBackendInternalWeb implements FMTCDriftBackendInternal {
  _FMTCDriftBackendInternalWeb._();

  @override
  String get friendlyIdentifier => 'Drift (Web)';

  DriftFMTCDatabase? _db;
  DriftFMTCDatabase get _expectDb => _db ?? (throw RootUnavailable());

  // `removeOldestTilesAboveLimit` tracking & debouncing
  Timer? _rotalDebouncer;
  int? _rotalStoresHash;
  Completer<Map<String, int>>? _rotalResultCompleter;

  // Lifecycle

  Future<void> initialise({
    required bool useInMemoryDatabase,
  }) async {
    if (_db != null) throw RootAlreadyInitialised();

    if (useInMemoryDatabase) {
      final sqlite3 = await WasmSqlite3.loadFromUrl(
        Uri.parse('sqlite3.wasm'),
      );
      sqlite3.registerVirtualFileSystem(
        InMemoryFileSystem(),
        makeDefault: true,
      );
      _db = DriftFMTCDatabase(WasmDatabase.inMemory(sqlite3));
    } else {
      final result = await WasmDatabase.open(
        databaseName: 'fmtc_drift',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );
      _db = DriftFMTCDatabase(result.resolvedExecutor);
    }

    // Ensure the singleton root stats row exists
    await _db!.into(_db!.driftRoot).insertOnConflictUpdate(
          DriftRootCompanion.insert(),
        );

    FMTCBackendAccess.internal = this;
    FMTCBackendAccessThreadSafe.internal =
        _FMTCDriftBackendInternalThreadSafeWeb._(_db!);
  }

  Future<void> uninitialise({required bool deleteRoot}) async {
    _expectDb;

    if (deleteRoot) {
      // On web, delete all data from tables
      await _db!.transaction(() async {
        await _db!.delete(_db!.driftStoreTile).go();
        await _db!.delete(_db!.driftTile).go();
        await _db!.delete(_db!.driftRecoveryRegion).go();
        await _db!.delete(_db!.driftRecovery).go();
        await _db!.delete(_db!.driftStore).go();
        await _db!.delete(_db!.driftRoot).go();
      });
    }

    await _db!.close();
    _db = null;

    _rotalDebouncer?.cancel();
    _rotalDebouncer = null;
    _rotalStoresHash = null;
    _rotalResultCompleter?.completeError(RootUnavailable());
    _rotalResultCompleter = null;

    FMTCBackendAccess.internal = null;
    FMTCBackendAccessThreadSafe.internal = null;
  }

  // Root stats

  // On web, realSize isn't meaningful (no file on disk). Return rootSize.
  @override
  Future<double> realSize() => rootSize();

  @override
  Future<double> rootSize() async {
    final root = await (_expectDb.select(_expectDb.driftRoot)
          ..where((r) => r.id.equals(0)))
        .getSingle();
    return root.size / 1024;
  }

  @override
  Future<int> rootLength() async {
    final root = await (_expectDb.select(_expectDb.driftRoot)
          ..where((r) => r.id.equals(0)))
        .getSingle();
    return root.length;
  }

  // Store management

  @override
  Future<List<String>> listStores() async {
    final query = _expectDb.select(_expectDb.driftStore)
      ..addColumns([_expectDb.driftStore.name]);
    final results = await query.get();
    return results.map((r) => r.name).toList();
  }

  @override
  Future<bool> storeExists({required String storeName}) async {
    final query = _expectDb.select(_expectDb.driftStore)
      ..where((s) => s.name.equals(storeName));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  @override
  Future<void> createStore({
    required String storeName,
    required int? maxLength,
  }) async {
    await _expectDb.into(_expectDb.driftStore).insertOnConflictUpdate(
          DriftStoreCompanion.insert(
            name: storeName,
            maxLength: Value(maxLength),
          ),
        );
  }

  @override
  Future<void> deleteStore({required String storeName}) async {
    final db = _expectDb;

    await db.transaction(() async {
      final tilesToCheck = await (db.select(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .get();
      final tileUids = tilesToCheck.map((st) => st.tile).toSet();

      await (db.delete(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .go();

      int orphanedSize = 0;
      int orphanedCount = 0;

      for (final tileUid in tileUids) {
        final remaining = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(tileUid)))
            .get();
        if (remaining.isEmpty) {
          final tile = await (db.select(db.driftTile)
                ..where((t) => t.uid.equals(tileUid)))
              .getSingleOrNull();
          if (tile != null) {
            orphanedSize += tile.bytes.lengthInBytes;
            orphanedCount++;
            await (db.delete(db.driftTile)..where((t) => t.uid.equals(tileUid)))
                .go();
          }
        }
      }

      if (orphanedCount > 0) {
        await _updateRootStats(
          db,
          deltaLength: -orphanedCount,
          deltaSize: -orphanedSize,
        );
      }

      await (db.delete(db.driftStore)..where((s) => s.name.equals(storeName)))
          .go();
    });
  }

  @override
  Future<void> resetStore({required String storeName}) async {
    final db = _expectDb;

    final storeRow = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingleOrNull();
    if (storeRow == null) throw StoreNotExists(storeName: storeName);

    await db.transaction(() async {
      final tilesToCheck = await (db.select(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .get();
      final tileUids = tilesToCheck.map((st) => st.tile).toSet();

      await (db.delete(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .go();

      int orphanedSize = 0;
      int orphanedCount = 0;

      for (final tileUid in tileUids) {
        final remaining = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(tileUid)))
            .get();
        if (remaining.isEmpty) {
          final tile = await (db.select(db.driftTile)
                ..where((t) => t.uid.equals(tileUid)))
              .getSingleOrNull();
          if (tile != null) {
            orphanedSize += tile.bytes.lengthInBytes;
            orphanedCount++;
            await (db.delete(db.driftTile)..where((t) => t.uid.equals(tileUid)))
                .go();
          }
        }
      }

      if (orphanedCount > 0) {
        await _updateRootStats(
          db,
          deltaLength: -orphanedCount,
          deltaSize: -orphanedSize,
        );
      }

      await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
          .write(
        const DriftStoreCompanion(
          length: Value(0),
          size: Value(0),
          hits: Value(0),
          misses: Value(0),
        ),
      );
    });
  }

  @override
  Future<void> renameStore({
    required String currentStoreName,
    required String newStoreName,
  }) async {
    final db = _expectDb;

    final storeRow = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(currentStoreName)))
        .getSingleOrNull();
    if (storeRow == null) throw StoreNotExists(storeName: currentStoreName);

    await (db.update(db.driftStore)
          ..where((s) => s.name.equals(currentStoreName)))
        .write(DriftStoreCompanion(name: Value(newStoreName)));
  }

  @override
  Future<int?> storeGetMaxLength({required String storeName}) async {
    final db = _expectDb;
    final store = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingleOrNull();
    if (store == null) throw StoreNotExists(storeName: storeName);
    return store.maxLength;
  }

  @override
  Future<void> storeSetMaxLength({
    required String storeName,
    required int? newMaxLength,
  }) async {
    final db = _expectDb;

    final store = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingleOrNull();
    if (store == null) throw StoreNotExists(storeName: storeName);

    await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
        .write(DriftStoreCompanion(maxLength: Value(newMaxLength)));
  }

  @override
  Future<({double size, int length, int hits, int misses})> getStoreStats({
    required String storeName,
  }) async {
    final db = _expectDb;
    final store = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingleOrNull();
    if (store == null) throw StoreNotExists(storeName: storeName);
    return (
      size: store.size / 1024,
      length: store.length,
      hits: store.hits,
      misses: store.misses,
    );
  }

  // Tile CRUD

  @override
  Future<bool> tileExists({
    required String url,
    required ({bool includeOrExclude, List<String> storeNames}) storeNames,
  }) async {
    final db = _expectDb;
    final resolvedStores = await _resolveReadableStoresFormat(db, storeNames);

    final query = db.select(db.driftTile).join([
      innerJoin(
        db.driftStoreTile,
        db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
      ),
    ])
      ..where(
        db.driftTile.uid.equals(url) &
            db.driftStoreTile.store.isIn(resolvedStores),
      );

    final result = await query.getSingleOrNull();
    return result != null;
  }

  @override
  Future<
      ({
        BackendTile? tile,
        List<String> intersectedStoreNames,
        List<String> allStoreNames,
      })> readTile({
    required String url,
    required ({bool includeOrExclude, List<String> storeNames}) storeNames,
  }) async {
    final db = _expectDb;
    final resolvedStores = await _resolveReadableStoresFormat(db, storeNames);

    final query = db.select(db.driftTile).join([
      innerJoin(
        db.driftStoreTile,
        db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
      ),
    ])
      ..where(
        db.driftTile.uid.equals(url) &
            db.driftStoreTile.store.isIn(resolvedStores),
      );

    final result = await query.getSingleOrNull();

    if (result == null) {
      return (
        tile: null,
        intersectedStoreNames: const <String>[],
        allStoreNames: const <String>[],
      );
    }

    final tileData = result.readTable(db.driftTile);

    final allStoresQuery = db.select(db.driftStoreTile)
      ..where((st) => st.tile.equals(url));
    final allStoresResult = await allStoresQuery.get();
    final allStoreNamesList =
        allStoresResult.map((st) => st.store).toList(growable: false);
    final intersectedStoreNames = allStoreNamesList
        .where(resolvedStores.contains)
        .toList(growable: false);

    return (
      tile: DriftBackendTile(
        url: tileData.uid,
        bytes: tileData.bytes,
        lastModified: tileData.lastModified,
      ),
      intersectedStoreNames: intersectedStoreNames,
      allStoreNames: allStoreNamesList,
    );
  }

  @override
  Future<BackendTile?> readLatestTile({required String storeName}) async {
    final db = _expectDb;

    final query = db.select(db.driftTile).join([
      innerJoin(
        db.driftStoreTile,
        db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
      ),
    ])
      ..where(db.driftStoreTile.store.equals(storeName))
      ..orderBy([OrderingTerm.desc(db.driftTile.lastModified)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final tileData = result.readTable(db.driftTile);
    return DriftBackendTile(
      url: tileData.uid,
      bytes: tileData.bytes,
      lastModified: tileData.lastModified,
    );
  }

  @override
  Future<Map<String, bool>> writeTile({
    required String url,
    required Uint8List bytes,
    required List<String> storeNames,
    required List<String>? writeAllNotIn,
  }) async {
    final db = _expectDb;

    final allStoreNames = await (db.select(db.driftStore)
          ..addColumns([db.driftStore.name]))
        .get()
        .then((rows) => rows.map((r) => r.name).toList());

    for (final storeName in storeNames) {
      if (!allStoreNames.contains(storeName)) {
        throw StoreNotExists(storeName: storeName);
      }
    }

    final compiledStoreNames = writeAllNotIn == null
        ? storeNames
        : [
            ...storeNames,
            ...allStoreNames.whereNot(
              (e) => writeAllNotIn.contains(e) || storeNames.contains(e),
            ),
          ];

    if (compiledStoreNames.isEmpty) return const {};

    final result = <String, bool>{
      for (final storeName in compiledStoreNames) storeName: false,
    };

    await db.transaction(() async {
      final existingTile = await (db.select(db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();

      if (existingTile != null) {
        final sizeDelta =
            bytes.lengthInBytes - existingTile.bytes.lengthInBytes;

        await _updateRootStats(db, deltaSize: sizeDelta);

        final currentStores = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(url)))
            .get();
        final currentStoreNames = currentStores.map((st) => st.store).toSet();

        for (final currentStoreName in currentStoreNames) {
          await (db.update(db.driftStore)
                ..where((s) => s.name.equals(currentStoreName)))
              .write(
            DriftStoreCompanion(
              size: Value(
                await _getStoreSize(db, currentStoreName) + sizeDelta,
              ),
            ),
          );
        }

        for (final storeName in compiledStoreNames) {
          if (!currentStoreNames.contains(storeName)) {
            result[storeName] = true;
            await db.into(db.driftStoreTile).insertOnConflictUpdate(
                  DriftStoreTileCompanion.insert(
                    store: storeName,
                    tile: url,
                  ),
                );
            final store = await (db.select(db.driftStore)
                  ..where((s) => s.name.equals(storeName)))
                .getSingle();
            await (db.update(db.driftStore)
                  ..where((s) => s.name.equals(storeName)))
                .write(
              DriftStoreCompanion(
                length: Value(store.length + 1),
                size: Value(store.size + bytes.lengthInBytes),
              ),
            );
          }
        }

        await (db.update(db.driftTile)..where((t) => t.uid.equals(url))).write(
          DriftTileCompanion(
            bytes: Value(bytes),
            lastModified: Value(DateTime.timestamp()),
          ),
        );
      } else {
        await _updateRootStats(
          db,
          deltaLength: 1,
          deltaSize: bytes.lengthInBytes,
        );

        await db.into(db.driftTile).insert(
              DriftTileCompanion.insert(
                uid: url,
                bytes: bytes,
              ),
            );

        for (final storeName in compiledStoreNames) {
          result[storeName] = true;

          await db.into(db.driftStoreTile).insertOnConflictUpdate(
                DriftStoreTileCompanion.insert(
                  store: storeName,
                  tile: url,
                ),
              );

          final store = await (db.select(db.driftStore)
                ..where((s) => s.name.equals(storeName)))
              .getSingle();
          await (db.update(db.driftStore)
                ..where((s) => s.name.equals(storeName)))
              .write(
            DriftStoreCompanion(
              length: Value(store.length + 1),
              size: Value(store.size + bytes.lengthInBytes),
            ),
          );
        }
      }
    });

    return result;
  }

  @override
  Future<bool?> deleteTile({
    required String storeName,
    required String url,
  }) async {
    final db = _expectDb;

    return db.transaction(() async {
      final tile = await (db.select(db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();
      if (tile == null) return null;

      final junction = await (db.select(db.driftStoreTile)
            ..where(
              (st) => st.store.equals(storeName) & st.tile.equals(url),
            ))
          .getSingleOrNull();
      if (junction == null) return null;

      await (db.delete(db.driftStoreTile)
            ..where(
              (st) => st.store.equals(storeName) & st.tile.equals(url),
            ))
          .go();

      final store = await (db.select(db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingle();
      await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
          .write(
        DriftStoreCompanion(
          length: Value(store.length - 1),
          size: Value(store.size - tile.bytes.lengthInBytes),
        ),
      );

      final remaining = await (db.select(db.driftStoreTile)
            ..where((st) => st.tile.equals(url)))
          .get();

      if (remaining.isEmpty) {
        await (db.delete(db.driftTile)..where((t) => t.uid.equals(url))).go();
        await _updateRootStats(
          db,
          deltaLength: -1,
          deltaSize: -tile.bytes.lengthInBytes,
        );
        return true;
      }

      return false;
    });
  }

  // Statistics

  @override
  Future<void> incrementStoreHits({
    required List<String> storeNames,
  }) async {
    final db = _expectDb;
    await db.transaction(() async {
      for (final storeName in storeNames) {
        final store = await (db.select(db.driftStore)
              ..where((s) => s.name.equals(storeName)))
            .getSingleOrNull();
        if (store == null) throw StoreNotExists(storeName: storeName);
        await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
            .write(DriftStoreCompanion(hits: Value(store.hits + 1)));
      }
    });
  }

  @override
  Future<void> incrementStoreMisses({
    required ({bool includeOrExclude, List<String> storeNames}) storeNames,
  }) async {
    final db = _expectDb;
    final resolvedStores = await _resolveReadableStoresFormat(db, storeNames);

    await db.transaction(() async {
      for (final storeName in resolvedStores) {
        final store = await (db.select(db.driftStore)
              ..where((s) => s.name.equals(storeName)))
            .getSingle();
        await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
            .write(DriftStoreCompanion(misses: Value(store.misses + 1)));
      }
    });
  }

  @override
  Future<Map<String, int>> removeOldestTilesAboveLimit({
    required List<String> storeNames,
  }) async {
    if (_rotalResultCompleter?.isCompleted ?? true) {
      _rotalResultCompleter = Completer<Map<String, int>>();
    }

    void doRemoval() => _rotalResultCompleter!.complete(
          _doRemoveOldestTilesAboveLimit(storeNames),
        );

    if (_rotalStoresHash != storeNames.hashCode) {
      _rotalStoresHash = storeNames.hashCode;
      if (_rotalDebouncer?.isActive ?? false) {
        _rotalDebouncer!.cancel();
        doRemoval();
        return _rotalResultCompleter!.future;
      }
    }

    final isAlreadyActive = _rotalDebouncer?.isActive ?? false;
    if (isAlreadyActive) _rotalDebouncer!.cancel();
    _rotalDebouncer = Timer(
      Duration(milliseconds: isAlreadyActive ? 500 : 1000),
      doRemoval,
    );

    return _rotalResultCompleter!.future;
  }

  Future<Map<String, int>> _doRemoveOldestTilesAboveLimit(
    List<String> storeNames,
  ) async {
    final db = _expectDb;
    final result = <String, int>{};

    for (final storeName in storeNames) {
      final store = await (db.select(db.driftStore)
            ..where(
              (s) => s.name.equals(storeName) & s.maxLength.isNotNull(),
            ))
          .getSingleOrNull();
      if (store == null) continue;

      final numToRemove = store.length - store.maxLength!;
      if (numToRemove <= 0) continue;

      final oldestTilesQuery = db.select(db.driftTile).join([
        innerJoin(
          db.driftStoreTile,
          db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
        ),
      ])
        ..where(db.driftStoreTile.store.equals(storeName))
        ..orderBy([OrderingTerm.asc(db.driftTile.lastModified)])
        ..limit(numToRemove);

      final oldestTiles = await oldestTilesQuery.get();
      int orphansCount = 0;

      await db.transaction(() async {
        for (final row in oldestTiles) {
          final tile = row.readTable(db.driftTile);

          await (db.delete(db.driftStoreTile)
                ..where(
                  (st) => st.store.equals(storeName) & st.tile.equals(tile.uid),
                ))
              .go();

          await (db.update(db.driftStore)
                ..where((s) => s.name.equals(storeName)))
              .write(
            DriftStoreCompanion(
              length: Value(
                (await (db.select(db.driftStore)
                              ..where((s) => s.name.equals(storeName)))
                            .getSingle())
                        .length -
                    1,
              ),
              size: Value(
                (await (db.select(db.driftStore)
                              ..where((s) => s.name.equals(storeName)))
                            .getSingle())
                        .size -
                    tile.bytes.lengthInBytes,
              ),
            ),
          );

          final remaining = await (db.select(db.driftStoreTile)
                ..where((st) => st.tile.equals(tile.uid)))
              .get();

          if (remaining.isEmpty) {
            await (db.delete(db.driftTile)
                  ..where((t) => t.uid.equals(tile.uid)))
                .go();
            await _updateRootStats(
              db,
              deltaLength: -1,
              deltaSize: -tile.bytes.lengthInBytes,
            );
            orphansCount++;
          }
        }
      });

      result[storeName] = orphansCount;
    }

    return result;
  }

  @override
  Future<int> removeTilesOlderThan({
    required String storeName,
    required DateTime expiry,
  }) async {
    final db = _expectDb;

    final query = db.select(db.driftTile).join([
      innerJoin(
        db.driftStoreTile,
        db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
      ),
    ])
      ..where(
        db.driftStoreTile.store.equals(storeName) &
            db.driftTile.lastModified.isSmallerThanValue(expiry),
      );

    final expiredTiles = await query.get();
    int orphansCount = 0;

    await db.transaction(() async {
      for (final row in expiredTiles) {
        final tile = row.readTable(db.driftTile);

        await (db.delete(db.driftStoreTile)
              ..where(
                (st) => st.store.equals(storeName) & st.tile.equals(tile.uid),
              ))
            .go();

        final store = await (db.select(db.driftStore)
              ..where((s) => s.name.equals(storeName)))
            .getSingle();
        await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
            .write(
          DriftStoreCompanion(
            length: Value(store.length - 1),
            size: Value(store.size - tile.bytes.lengthInBytes),
          ),
        );

        final remaining = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(tile.uid)))
            .get();

        if (remaining.isEmpty) {
          await (db.delete(db.driftTile)..where((t) => t.uid.equals(tile.uid)))
              .go();
          await _updateRootStats(
            db,
            deltaLength: -1,
            deltaSize: -tile.bytes.lengthInBytes,
          );
          orphansCount++;
        }
      }
    });

    return orphansCount;
  }

  // Metadata

  @override
  Future<Map<String, String>> readMetadata({
    required String storeName,
  }) async {
    final db = _expectDb;
    final store = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingleOrNull();
    if (store == null) throw StoreNotExists(storeName: storeName);

    return (jsonDecode(store.metadataJson) as Map<String, dynamic>)
        .cast<String, String>();
  }

  @override
  Future<void> setMetadata({
    required String storeName,
    required String key,
    required String value,
  }) =>
      setBulkMetadata(storeName: storeName, kvs: {key: value});

  @override
  Future<void> setBulkMetadata({
    required String storeName,
    required Map<String, String> kvs,
  }) async {
    final db = _expectDb;

    await db.transaction(() async {
      final store = await (db.select(db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingleOrNull();
      if (store == null) throw StoreNotExists(storeName: storeName);

      final metadata = jsonDecode(store.metadataJson) as Map<String, dynamic>
        ..addAll(kvs);

      await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
          .write(
        DriftStoreCompanion(metadataJson: Value(jsonEncode(metadata))),
      );
    });
  }

  @override
  Future<String?> removeMetadata({
    required String storeName,
    required String key,
  }) async {
    final db = _expectDb;

    return db.transaction(() async {
      final store = await (db.select(db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingleOrNull();
      if (store == null) throw StoreNotExists(storeName: storeName);

      final metadata = jsonDecode(store.metadataJson) as Map<String, dynamic>;
      final removedVal = metadata.remove(key) as String?;

      await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
          .write(
        DriftStoreCompanion(metadataJson: Value(jsonEncode(metadata))),
      );

      return removedVal;
    });
  }

  @override
  Future<void> resetMetadata({required String storeName}) async {
    final db = _expectDb;

    final store = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingleOrNull();
    if (store == null) throw StoreNotExists(storeName: storeName);

    await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
        .write(const DriftStoreCompanion(metadataJson: Value('{}')));
  }

  // Recovery

  @override
  Future<List<RecoveredRegion>> listRecoverableRegions() async {
    final db = _expectDb;
    final recoveries = await db.select(db.driftRecovery).get();
    final allRegions = await db.select(db.driftRecoveryRegion).get();

    return recoveries.map((r) {
      final rootRegion = allRegions.firstWhere(
        (rr) => rr.recovery == r.id && rr.parentRegionId == null,
      );

      return RecoveredRegion(
        id: r.id,
        storeName: r.store,
        time: r.creationTime,
        minZoom: r.minZoom,
        maxZoom: r.maxZoom,
        start: r.startTile,
        end: r.endTile,
        region: dataToRegion(rootRegion, allRegions),
      );
    }).toList(growable: false);
  }

  @override
  Future<RecoveredRegion> getRecoverableRegion({required int id}) async {
    final db = _expectDb;
    final recovery = await (db.select(db.driftRecovery)
          ..where((r) => r.id.equals(id)))
        .getSingle();
    final allRegions = await (db.select(db.driftRecoveryRegion)
          ..where((rr) => rr.recovery.equals(id)))
        .get();

    final rootRegion = allRegions.firstWhere(
      (rr) => rr.parentRegionId == null,
    );

    return RecoveredRegion(
      id: recovery.id,
      storeName: recovery.store,
      time: recovery.creationTime,
      minZoom: recovery.minZoom,
      maxZoom: recovery.maxZoom,
      start: recovery.startTile,
      end: recovery.endTile,
      region: dataToRegion(rootRegion, allRegions),
    );
  }

  @override
  Future<void> cancelRecovery({required int id}) async {
    final db = _expectDb;
    await db.transaction(() async {
      await (db.delete(db.driftRecoveryRegion)
            ..where((rr) => rr.recovery.equals(id)))
          .go();
      await (db.delete(db.driftRecovery)..where((r) => r.id.equals(id))).go();
    });
  }

  @override
  Stream<void> watchRecovery({required bool triggerImmediately}) {
    final db = _expectDb;
    final query = db.select(db.driftRecovery);
    final stream = query.watch().map((_) {});
    if (triggerImmediately) {
      return Stream.multi((controller) {
        controller.add(null);
        stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      });
    }
    return stream;
  }

  // Watchers

  @override
  Stream<void> watchStores({
    required List<String> storeNames,
    required bool triggerImmediately,
  }) {
    final db = _expectDb;
    final query = db.select(db.driftStore)
      ..where((s) => s.name.isIn(storeNames));
    final stream = query.watch().map((_) {});
    if (triggerImmediately) {
      return Stream.multi((controller) {
        controller.add(null);
        stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      });
    }
    return stream;
  }

  // Import/Export — not supported on web

  @override
  Future<int> exportStores({
    required List<String> storeNames,
    required String path,
  }) =>
      throw UnsupportedError(
        'Import/export is not supported on web. '
        'Use the native backend for file-based import/export.',
      );

  @override
  ImportResult importStores({
    required String path,
    required ImportConflictStrategy strategy,
    required List<String>? storeNames,
  }) =>
      throw UnsupportedError(
        'Import/export is not supported on web. '
        'Use the native backend for file-based import/export.',
      );

  @override
  Future<List<String>> listImportableStores({required String path}) =>
      throw UnsupportedError(
        'Import/export is not supported on web. '
        'Use the native backend for file-based import/export.',
      );

  // Helper methods

  Future<int> _getStoreSize(DriftFMTCDatabase db, String storeName) async {
    final store = await (db.select(db.driftStore)
          ..where((s) => s.name.equals(storeName)))
        .getSingle();
    return store.size;
  }

  Future<void> _updateRootStats(
    DriftFMTCDatabase db, {
    int deltaLength = 0,
    int deltaSize = 0,
  }) async {
    final root = await (db.select(db.driftRoot)..where((r) => r.id.equals(0)))
        .getSingle();
    await (db.update(db.driftRoot)..where((r) => r.id.equals(0))).write(
      DriftRootCompanion(
        length: Value(root.length + deltaLength),
        size: Value(root.size + deltaSize),
      ),
    );
  }

  Future<List<String>> _resolveReadableStoresFormat(
    DriftFMTCDatabase db,
    ({bool includeOrExclude, List<String> storeNames}) readableStores,
  ) async {
    if (!readableStores.includeOrExclude) {
      final allStores = await db.select(db.driftStore).get();
      final allNames = allStores.map((s) => s.name);
      return allNames
          .whereNot((e) => readableStores.storeNames.contains(e))
          .toList(growable: false);
    }

    for (final storeName in readableStores.storeNames) {
      final exists = await (db.select(db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingleOrNull();
      if (exists == null) throw StoreNotExists(storeName: storeName);
    }

    return readableStores.storeNames;
  }
}

/// Web thread-safe implementation — on web there are no true isolates,
/// so this simply wraps the same database instance.
class _FMTCDriftBackendInternalThreadSafeWeb
    implements FMTCBackendInternalThreadSafe {
  _FMTCDriftBackendInternalThreadSafeWeb._(this._db);

  @override
  String get friendlyIdentifier => 'Drift (Web)';

  final DriftFMTCDatabase _db;

  @override
  void initialise() {
    // No-op on web — we share the same DB instance
  }

  @override
  void uninitialise() {
    // No-op on web — lifecycle managed by main backend
  }

  @override
  FMTCBackendInternalThreadSafe duplicate() =>
      _FMTCDriftBackendInternalThreadSafeWeb._(_db);

  @override
  Future<BackendTile?> readTile({
    required String url,
    String? storeName,
  }) async {
    if (storeName != null) {
      final query = _db.select(_db.driftTile).join([
        innerJoin(
          _db.driftStoreTile,
          _db.driftStoreTile.tile.equalsExp(_db.driftTile.uid),
        ),
      ])
        ..where(
          _db.driftTile.uid.equals(url) &
              _db.driftStoreTile.store.equals(storeName),
        );

      final result = await query.getSingleOrNull();
      if (result == null) return null;

      final tileData = result.readTable(_db.driftTile);
      return DriftBackendTile(
        url: tileData.uid,
        bytes: tileData.bytes,
        lastModified: tileData.lastModified,
      );
    } else {
      final tile = await (_db.select(_db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();
      if (tile == null) return null;

      return DriftBackendTile(
        url: tile.uid,
        bytes: tile.bytes,
        lastModified: tile.lastModified,
      );
    }
  }

  @override
  Future<void> writeTile({
    required String storeName,
    required String url,
    required Uint8List bytes,
  }) async {
    await _db.transaction(() async {
      final existingTile = await (_db.select(_db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();

      final store = await (_db.select(_db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingleOrNull();
      if (store == null) throw StoreNotExists(storeName: storeName);

      if (existingTile != null) {
        final sizeDelta =
            bytes.lengthInBytes - existingTile.bytes.lengthInBytes;

        final junction = await (_db.select(_db.driftStoreTile)
              ..where(
                (st) => st.store.equals(storeName) & st.tile.equals(url),
              ))
            .getSingleOrNull();

        final relatedStores = await (_db.select(_db.driftStoreTile)
              ..where((st) => st.tile.equals(url)))
            .get();
        for (final rel in relatedStores) {
          final relStore = await (_db.select(_db.driftStore)
                ..where((s) => s.name.equals(rel.store)))
              .getSingle();
          await (_db.update(_db.driftStore)
                ..where((s) => s.name.equals(rel.store)))
              .write(
            DriftStoreCompanion(size: Value(relStore.size + sizeDelta)),
          );
        }

        final root = await (_db.select(_db.driftRoot)
              ..where((r) => r.id.equals(0)))
            .getSingle();
        await (_db.update(_db.driftRoot)..where((r) => r.id.equals(0)))
            .write(DriftRootCompanion(size: Value(root.size + sizeDelta)));

        if (junction == null) {
          await _db.into(_db.driftStoreTile).insert(
                DriftStoreTileCompanion.insert(
                  store: storeName,
                  tile: url,
                ),
              );
          await (_db.update(_db.driftStore)
                ..where((s) => s.name.equals(storeName)))
              .write(
            DriftStoreCompanion(
              length: Value(store.length + 1),
              size: Value(store.size + bytes.lengthInBytes),
            ),
          );
        }

        await (_db.update(_db.driftTile)..where((t) => t.uid.equals(url)))
            .write(
          DriftTileCompanion(
            bytes: Value(bytes),
            lastModified: Value(DateTime.timestamp()),
          ),
        );
      } else {
        await _db.into(_db.driftTile).insert(
              DriftTileCompanion.insert(uid: url, bytes: bytes),
            );
        await _db.into(_db.driftStoreTile).insert(
              DriftStoreTileCompanion.insert(store: storeName, tile: url),
            );
        await (_db.update(_db.driftStore)
              ..where((s) => s.name.equals(storeName)))
            .write(
          DriftStoreCompanion(
            length: Value(store.length + 1),
            size: Value(store.size + bytes.lengthInBytes),
          ),
        );

        final root = await (_db.select(_db.driftRoot)
              ..where((r) => r.id.equals(0)))
            .getSingle();
        await (_db.update(_db.driftRoot)..where((r) => r.id.equals(0))).write(
          DriftRootCompanion(
            length: Value(root.length + 1),
            size: Value(root.size + bytes.lengthInBytes),
          ),
        );
      }
    });
  }

  @override
  Future<void> writeTiles({
    required String storeName,
    required List<String> urls,
    required List<Uint8List> bytess,
  }) async {
    await _db.transaction(() async {
      for (int i = 0; i < urls.length; i++) {
        await writeTile(storeName: storeName, url: urls[i], bytes: bytess[i]);
      }
    });
  }

  @override
  Future<void> startRecovery({
    required int id,
    required String storeName,
    required DownloadableRegion region,
    required int tilesCount,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.driftRecovery).insert(
            DriftRecoveryCompanion.insert(
              id: Value(id),
              store: storeName,
              minZoom: region.minZoom,
              maxZoom: region.maxZoom,
              startTile: region.start,
              endTile: region.end ?? (region.start - 1 + tilesCount),
            ),
          );

      Future<void> insertRegion(
        BaseRegion baseRegion,
        int? parentId,
      ) async {
        final companion = regionToCompanion(
          region: baseRegion,
          recoveryId: id,
          parentRegionId: parentId,
        );

        final regionId =
            await _db.into(_db.driftRecoveryRegion).insert(companion);

        if (baseRegion case final MultiRegion multiRegion) {
          for (final subRegion in multiRegion.regions) {
            await insertRegion(subRegion, regionId);
          }
        }
      }

      await insertRegion(region.originalRegion, null);
    });
  }

  @override
  Future<void> updateRecovery({
    required int id,
    required int newStartTile,
  }) async {
    await (_db.update(_db.driftRecovery)..where((r) => r.id.equals(id)))
        .write(DriftRecoveryCompanion(startTile: Value(newStartTile)));
  }
}
