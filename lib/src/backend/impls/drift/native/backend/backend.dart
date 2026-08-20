// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../../../flutter_map_tile_caching.dart';
import '../../../../export_internal.dart';
import '../database/database.dart';
import '../database/models/root.drift.dart';
import '../database/models/store.drift.dart';
import '../database/models/store_tile.drift.dart' show DriftStoreTileCompanion;
import '../database/models/tile.drift.dart';
import 'models/drift_backend_tile.dart';
import 'thread_safe.dart';
import 'utils/region_serialization.dart';

/// Implementation of [FMTCBackend] that uses Drift (SQLite) as the storage
/// database
final class FMTCDriftBackend implements FMTCBackend {
  /// {@macro fmtc.backend.initialise}
  ///
  /// Avoid using [useInMemoryDatabase] outside of testing purposes.
  @override
  Future<void> initialise({
    String? rootDirectory,
    @visibleForTesting bool useInMemoryDatabase = false,
  }) =>
      FMTCDriftBackendInternal._instance.initialise(
        rootDirectory: rootDirectory,
        useInMemoryDatabase: useInMemoryDatabase,
      );

  /// {@macro fmtc.backend.uninitialise}
  @override
  Future<void> uninitialise({
    bool deleteRoot = false,
  }) =>
      FMTCDriftBackendInternal._instance.uninitialise(deleteRoot: deleteRoot);
}

/// Internal implementation of [FMTCBackend] that uses Drift as the storage
/// database
///
/// Unlike ObjectBox, Drift handles background isolate operations internally
/// via `NativeDatabase.createInBackground()`, so no manual worker isolate
/// management is needed.
abstract interface class FMTCDriftBackendInternal
    implements FMTCBackendInternal {
  static final _instance = _FMTCDriftBackendInternal._();
}

class _FMTCDriftBackendInternal implements FMTCDriftBackendInternal {
  _FMTCDriftBackendInternal._();

  @override
  String get friendlyIdentifier => 'Drift';

  DriftFMTCDatabase? _db;
  DriftFMTCDatabase get _expectDb => _db ?? (throw RootUnavailable());

  late String rootDirectory;
  late String _databasePath;

  // `removeOldestTilesAboveLimit` tracking & debouncing
  Timer? _rotalDebouncer;
  int? _rotalStoresHash;
  Completer<Map<String, int>>? _rotalResultCompleter;

  // Lifecycle

  Future<void> initialise({
    required String? rootDirectory,
    required bool useInMemoryDatabase,
  }) async {
    if (_db != null) throw RootAlreadyInitialised();

    if (useInMemoryDatabase) {
      this.rootDirectory = ':memory:';
      _databasePath = ':memory:';
      _db = DriftFMTCDatabase(NativeDatabase.memory());
    } else {
      final dir = rootDirectory ??
          (await getApplicationDocumentsDirectory()).absolute.path;
      this.rootDirectory = path.join(dir, 'fmtc');
      _databasePath = path.join(this.rootDirectory, 'fmtc_drift.db');

      await Directory(this.rootDirectory).create(recursive: true);

      _db = DriftFMTCDatabase(
        NativeDatabase.createInBackground(File(_databasePath)),
      );
    }

    // Ensure the singleton root stats row exists
    await _db!.into(_db!.driftRoot).insertOnConflictUpdate(
          DriftRootCompanion.insert(id: const Value(0)),
        );

    FMTCBackendAccess.internal = this;
    FMTCBackendAccessThreadSafe.internal =
        FMTCDriftBackendInternalThreadSafe.fromPath(_databasePath);
  }

  Future<void> uninitialise({required bool deleteRoot}) async {
    _expectDb;

    await _db!.close();
    _db = null;

    if (deleteRoot && rootDirectory != ':memory:') {
      final dir = Directory(rootDirectory);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }

    _rotalDebouncer?.cancel();
    _rotalDebouncer = null;
    _rotalStoresHash = null;
    _rotalResultCompleter?.completeError(RootUnavailable());
    _rotalResultCompleter = null;

    FMTCBackendAccess.internal = null;
    FMTCBackendAccessThreadSafe.internal = null;
  }

  // Root stats

  @override
  Future<double> realSize() async {
    _expectDb;
    if (_databasePath == ':memory:') return 0;
    final file = File(_databasePath);
    if (!await file.exists()) return 0;
    return (await file.length()) / 1024;
  }

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
      // Get all tiles that belong to this store
      final tilesToCheck = await (db.select(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .get();
      final tileUids = tilesToCheck.map((st) => st.tile).toSet();

      // Delete all junction entries for this store
      await (db.delete(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .go();

      // Find orphaned tiles (no longer in any store)
      int orphanedSize = 0;
      int orphanedCount = 0;

      for (final tileUid in tileUids) {
        final remaining = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(tileUid)))
            .get();
        if (remaining.isEmpty) {
          // Tile is orphaned — get its size and delete it
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

      // Update root stats
      if (orphanedCount > 0) {
        await _updateRootStats(
          db,
          deltaLength: -orphanedCount,
          deltaSize: -orphanedSize,
        );
      }

      // Delete the store itself
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
      // Get all tiles that belong to this store
      final tilesToCheck = await (db.select(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .get();
      final tileUids = tilesToCheck.map((st) => st.tile).toSet();

      // Delete all junction entries for this store
      await (db.delete(db.driftStoreTile)
            ..where((st) => st.store.equals(storeName)))
          .go();

      // Find and delete orphaned tiles
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

      // Update root stats
      if (orphanedCount > 0) {
        await _updateRootStats(
          db,
          deltaLength: -orphanedCount,
          deltaSize: -orphanedSize,
        );
      }

      // Reset store stats
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

    // CASCADE on DriftStoreTile handles junction updates automatically
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

    // First, check if the tile exists in any of the resolved stores
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

    // Get all stores this tile belongs to
    final allStoresQuery = db.select(db.driftStoreTile)
      ..where((st) => st.tile.equals(url));
    final allStoresResult = await allStoresQuery.get();
    final allStoreNames =
        allStoresResult.map((st) => st.store).toList(growable: false);
    final intersectedStoreNames =
        allStoreNames.where(resolvedStores.contains).toList(growable: false);

    return (
      tile: DriftBackendTile(
        url: tileData.uid,
        bytes: tileData.bytes,
        lastModified: tileData.lastModified,
      ),
      intersectedStoreNames: intersectedStoreNames,
      allStoreNames: allStoreNames,
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

    // Resolve all available store names
    final allStoreNames = await (db.select(db.driftStore)
          ..addColumns([db.driftStore.name]))
        .get()
        .then((rows) => rows.map((r) => r.name).toList());

    // Validate requested stores exist
    for (final storeName in storeNames) {
      if (!allStoreNames.contains(storeName)) {
        throw StoreNotExists(storeName: storeName);
      }
    }

    // Compile final store list
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
      // Check for existing tile
      final existingTile = await (db.select(db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();

      if (existingTile != null) {
        final sizeDelta =
            bytes.lengthInBytes - existingTile.bytes.lengthInBytes;

        // Update root stats for size change
        await _updateRootStats(db, deltaSize: sizeDelta);

        // Get all stores this tile currently belongs to
        final currentStores = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(url)))
            .get();
        final currentStoreNames = currentStores.map((st) => st.store).toSet();

        // Update size for all currently related stores
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

        // Add to new stores
        for (final storeName in compiledStoreNames) {
          if (!currentStoreNames.contains(storeName)) {
            result[storeName] = true;
            await db.into(db.driftStoreTile).insertOnConflictUpdate(
                  DriftStoreTileCompanion.insert(
                    store: storeName,
                    tile: url,
                  ),
                );
            // Update store length and size
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

        // Update the tile data
        await (db.update(db.driftTile)..where((t) => t.uid.equals(url))).write(
          DriftTileCompanion(
            bytes: Value(bytes),
            lastModified: Value(DateTime.timestamp()),
          ),
        );
      } else {
        // New tile — update root stats
        await _updateRootStats(
          db,
          deltaLength: 1,
          deltaSize: bytes.lengthInBytes,
        );

        // Insert the tile
        await db.into(db.driftTile).insert(
              DriftTileCompanion.insert(
                uid: url,
                bytes: bytes,
              ),
            );

        // Link to all target stores and update their stats
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
      // Check tile exists
      final tile = await (db.select(db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();
      if (tile == null) return null;

      // Check if tile is in this store
      final junction = await (db.select(db.driftStoreTile)
            ..where(
              (st) => st.store.equals(storeName) & st.tile.equals(url),
            ))
          .getSingleOrNull();
      if (junction == null) return null;

      // Remove from store
      await (db.delete(db.driftStoreTile)
            ..where(
              (st) => st.store.equals(storeName) & st.tile.equals(url),
            ))
          .go();

      // Update store stats
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

      // Check if tile is now orphaned
      final remaining = await (db.select(db.driftStoreTile)
            ..where((st) => st.tile.equals(url)))
          .get();

      if (remaining.isEmpty) {
        // Tile is orphaned — delete it and update root stats
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
    // Port the same debouncing logic from ObjectBox
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

      // Get oldest tiles in this store
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

          // Remove from this store
          await (db.delete(db.driftStoreTile)
                ..where(
                  (st) => st.store.equals(storeName) & st.tile.equals(tile.uid),
                ))
              .go();

          // Update store stats
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

          // Check if orphaned
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

    // Get tiles older than expiry in this store
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

        // Remove from store
        await (db.delete(db.driftStoreTile)
              ..where(
                (st) => st.store.equals(storeName) & st.tile.equals(tile.uid),
              ))
            .go();

        // Update store stats
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

        // Check if orphaned
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
      // Find the root region (no parentRegionId)
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

  // Import/Export

  @override
  Future<int> exportStores({
    required List<String> storeNames,
    required String path,
  }) async {
    if (storeNames.isEmpty) {
      throw ArgumentError.value(storeNames, 'storeNames', 'must not be empty');
    }

    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      throw ImportExportPathNotFile();
    }

    final db = _expectDb;

    // Create a temporary database for export
    final exportFile = File(path);
    final exportDb = DriftFMTCDatabase(NativeDatabase(exportFile));

    try {
      // Ensure root row exists in export db
      await exportDb.into(exportDb.driftRoot).insertOnConflictUpdate(
            DriftRootCompanion.insert(),
          );

      int totalTiles = 0;

      for (final storeName in storeNames) {
        final store = await (db.select(db.driftStore)
              ..where((s) => s.name.equals(storeName)))
            .getSingleOrNull();
        if (store == null) continue;

        // Copy store
        await exportDb.into(exportDb.driftStore).insertOnConflictUpdate(
              DriftStoreCompanion.insert(
                name: store.name,
                maxLength: Value(store.maxLength),
                length: Value(store.length),
                size: Value(store.size),
                hits: Value(store.hits),
                misses: Value(store.misses),
                metadataJson: Value(store.metadataJson),
              ),
            );

        // Copy tiles
        final tiles = await (db.select(db.driftTile).join([
          innerJoin(
            db.driftStoreTile,
            db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
          ),
        ])
              ..where(db.driftStoreTile.store.equals(storeName)))
            .get();

        for (final row in tiles) {
          final tile = row.readTable(db.driftTile);
          await exportDb.into(exportDb.driftTile).insertOnConflictUpdate(
                DriftTileCompanion.insert(
                  uid: tile.uid,
                  bytes: tile.bytes,
                  lastModified: Value(tile.lastModified),
                ),
              );
          await exportDb.into(exportDb.driftStoreTile).insertOnConflictUpdate(
                DriftStoreTileCompanion.insert(
                  store: storeName,
                  tile: tile.uid,
                ),
              );
          totalTiles++;
        }
      }

      await exportDb.close();

      // Append FMTC footer signature
      exportFile.openSync(mode: FileMode.append)
        ..writeFromSync([0xFF, 0xFF]) // separator
        ..writeStringSync('Drift')
        ..writeFromSync([0xFF, 0xFF]) // separator
        ..writeStringSync('FMTC')
        ..closeSync();

      return totalTiles;
    } catch (e) {
      await exportDb.close();
      rethrow;
    }
  }

  @override
  ImportResult importStores({
    required String path,
    required ImportConflictStrategy strategy,
    required List<String>? storeNames,
  }) {
    final storesToStates = Completer<StoresToStates>();
    final complete = Completer<int>();

    _doImport(
      path: path,
      strategy: strategy,
      storeNames: storeNames,
      storesToStates: storesToStates,
      complete: complete,
    );

    return (
      storesToStates: storesToStates.future,
      complete: complete.future,
    );
  }

  Future<void> _doImport({
    required String path,
    required ImportConflictStrategy strategy,
    required List<String>? storeNames,
    required Completer<StoresToStates> storesToStates,
    required Completer<int> complete,
  }) async {
    try {
      await _checkImportPathType(path);

      final importFile = File(path);
      _verifyImportableArchive(importFile);

      final importDb = DriftFMTCDatabase(NativeDatabase(importFile));
      final db = _expectDb;

      try {
        final availableStores =
            await importDb.select(importDb.driftStore).get();
        final targetStores = storeNames == null
            ? availableStores
            : availableStores
                .where((s) => storeNames.contains(s.name))
                .toList();

        final states = <String, ({String? name, bool hadConflict})>{};

        for (final importStore in targetStores) {
          final existingStore = await (db.select(db.driftStore)
                ..where((s) => s.name.equals(importStore.name)))
              .getSingleOrNull();

          final hadConflict = existingStore != null;
          String? finalName = importStore.name;

          if (hadConflict) {
            switch (strategy) {
              case ImportConflictStrategy.skip:
                states[importStore.name] = (name: null, hadConflict: true);
                continue;
              case ImportConflictStrategy.rename:
                int suffix = 1;
                while (await (db.select(db.driftStore)
                          ..where(
                            (s) => s.name.equals('${importStore.name}_$suffix'),
                          ))
                        .getSingleOrNull() !=
                    null) {
                  suffix++;
                }
                finalName = '${importStore.name}_$suffix';
              case ImportConflictStrategy.replace:
                await deleteStore(storeName: importStore.name);
              case ImportConflictStrategy.merge:
                break;
            }
          }

          states[importStore.name] =
              (name: finalName, hadConflict: hadConflict);

          // Create/ensure store exists
          await db.into(db.driftStore).insertOnConflictUpdate(
                DriftStoreCompanion.insert(
                  name: finalName,
                  maxLength: Value(importStore.maxLength),
                ),
              );

          // Copy tiles
          final tiles = await (importDb.select(importDb.driftTile).join([
            innerJoin(
              importDb.driftStoreTile,
              importDb.driftStoreTile.tile.equalsExp(importDb.driftTile.uid),
            ),
          ])
                ..where(importDb.driftStoreTile.store.equals(importStore.name)))
              .get();

          for (final row in tiles) {
            final tile = row.readTable(importDb.driftTile);
            await db.into(db.driftTile).insertOnConflictUpdate(
                  DriftTileCompanion.insert(
                    uid: tile.uid,
                    bytes: tile.bytes,
                    lastModified: Value(tile.lastModified),
                  ),
                );
            await db.into(db.driftStoreTile).insertOnConflictUpdate(
                  DriftStoreTileCompanion.insert(
                    store: finalName,
                    tile: tile.uid,
                  ),
                );
          }
        }

        if (!storesToStates.isCompleted) {
          storesToStates.complete(states);
        }

        // Recalculate stats for all affected stores
        for (final entry in states.entries) {
          final name = entry.value.name;
          if (name == null) continue;
          await _recalculateStoreStats(db, name);
        }
        await _recalculateRootStats(db);

        await importDb.close();

        if (!complete.isCompleted) {
          final totalTiles = states.values.where((s) => s.name != null).length;
          complete.complete(totalTiles);
        }
      } catch (e) {
        await importDb.close();
        rethrow;
      }
    } catch (e, st) {
      if (!storesToStates.isCompleted) {
        storesToStates.completeError(e, st);
      }
      if (!complete.isCompleted) {
        complete.completeError(e, st);
      }
    }
  }

  @override
  Future<List<String>> listImportableStores({required String path}) async {
    await _checkImportPathType(path);

    final importFile = File(path);
    _verifyImportableArchive(importFile);

    final importDb = DriftFMTCDatabase(NativeDatabase(importFile));

    try {
      final stores = await importDb.select(importDb.driftStore).get();
      await importDb.close();
      return stores.map((s) => s.name).toList();
    } catch (e) {
      await importDb.close();
      rethrow;
    }
  }

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

    // Verify all stores exist
    for (final storeName in readableStores.storeNames) {
      final exists = await (db.select(db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingleOrNull();
      if (exists == null) throw StoreNotExists(storeName: storeName);
    }

    return readableStores.storeNames;
  }

  Future<void> _checkImportPathType(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.notFound) {
      throw ImportPathNotExists(path: path);
    }
    if (type == FileSystemEntityType.directory) {
      throw ImportExportPathNotFile();
    }
  }

  void _verifyImportableArchive(File importFile) {
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

      // Check for expected backend identifier ("**Drift")
      const id = [255, 255, 68, 114, 105, 102, 116];
      for (int i = 6; i >= 0; i--) {
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

  Future<void> _recalculateStoreStats(
    DriftFMTCDatabase db,
    String storeName,
  ) async {
    final tiles = await (db.select(db.driftTile).join([
      innerJoin(
        db.driftStoreTile,
        db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
      ),
    ])
          ..where(db.driftStoreTile.store.equals(storeName)))
        .get();

    int totalSize = 0;
    for (final row in tiles) {
      totalSize += row.readTable(db.driftTile).bytes.lengthInBytes;
    }

    await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
        .write(
      DriftStoreCompanion(
        length: Value(tiles.length),
        size: Value(totalSize),
      ),
    );
  }

  Future<void> _recalculateRootStats(DriftFMTCDatabase db) async {
    final tileCount = await db.select(db.driftTile).get();

    int totalSize = 0;
    for (final tile in tileCount) {
      totalSize += tile.bytes.lengthInBytes;
    }

    await (db.update(db.driftRoot)..where((r) => r.id.equals(0))).write(
      DriftRootCompanion(
        length: Value(tileCount.length),
        size: Value(totalSize),
      ),
    );
  }
}
