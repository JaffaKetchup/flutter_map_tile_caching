// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../../../../../flutter_map_tile_caching.dart';
import '../../../../export_internal.dart';
import '../database/database.dart';
import '../database/models/recovery.drift.dart';
import '../database/models/root.drift.dart';
import '../database/models/store.drift.dart' show DriftStoreCompanion;
import '../database/models/store_tile.drift.dart';
import '../database/models/tile.drift.dart';
import 'models/drift_backend_tile.dart';
import 'utils/region_serialization.dart';

/// Thread-safe implementation for Drift backend, used by bulk download isolates
///
/// Unlike ObjectBox's `Store.attach()`, Drift uses standard SQLite connections.
/// Each isolate gets its own connection to the same database file.
/// WAL mode (default in modern SQLite) supports concurrent readers.
class FMTCDriftBackendInternalThreadSafe
    implements FMTCBackendInternalThreadSafe {
  /// Creates an instance from the given [databasePath] to the SQLite file
  FMTCDriftBackendInternalThreadSafe.fromPath(String databasePath)
      : _databasePath = databasePath;

  @override
  String get friendlyIdentifier => 'Drift';

  final String _databasePath;
  DriftFMTCDatabase? _db;
  DriftFMTCDatabase get _expectDb => _db ?? (throw RootUnavailable());

  @override
  void initialise() {
    if (_db != null) throw RootAlreadyInitialised();
    if (_databasePath == ':memory:') {
      _db = DriftFMTCDatabase(NativeDatabase.memory());
    } else {
      _db = DriftFMTCDatabase(NativeDatabase(File(_databasePath)));
    }
  }

  @override
  void uninitialise() {
    _expectDb;
    _db!.close();
    _db = null;
  }

  @override
  FMTCDriftBackendInternalThreadSafe duplicate() =>
      FMTCDriftBackendInternalThreadSafe.fromPath(_databasePath);

  @override
  Future<BackendTile?> readTile({
    required String url,
    String? storeName,
  }) async {
    final db = _expectDb;

    if (storeName != null) {
      final query = db.select(db.driftTile).join([
        innerJoin(
          db.driftStoreTile,
          db.driftStoreTile.tile.equalsExp(db.driftTile.uid),
        ),
      ])
        ..where(
          db.driftTile.uid.equals(url) &
              db.driftStoreTile.store.equals(storeName),
        );

      final result = await query.getSingleOrNull();
      if (result == null) return null;

      final tileData = result.readTable(db.driftTile);
      return DriftBackendTile(
        url: tileData.uid,
        bytes: tileData.bytes,
        lastModified: tileData.lastModified,
      );
    } else {
      final tile = await (db.select(db.driftTile)
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
    final db = _expectDb;

    await db.transaction(() async {
      final existingTile = await (db.select(db.driftTile)
            ..where((t) => t.uid.equals(url)))
          .getSingleOrNull();

      final store = await (db.select(db.driftStore)
            ..where((s) => s.name.equals(storeName)))
          .getSingleOrNull();
      if (store == null) throw StoreNotExists(storeName: storeName);

      if (existingTile != null) {
        final sizeDelta =
            bytes.lengthInBytes - existingTile.bytes.lengthInBytes;

        // Check if tile is already in this store
        final junction = await (db.select(db.driftStoreTile)
              ..where(
                (st) => st.store.equals(storeName) & st.tile.equals(url),
              ))
            .getSingleOrNull();

        // Update all related stores' sizes
        final relatedStores = await (db.select(db.driftStoreTile)
              ..where((st) => st.tile.equals(url)))
            .get();
        for (final rel in relatedStores) {
          final relStore = await (db.select(db.driftStore)
                ..where((s) => s.name.equals(rel.store)))
              .getSingle();
          await (db.update(db.driftStore)
                ..where((s) => s.name.equals(rel.store)))
              .write(
            DriftStoreCompanion(
              size: Value(relStore.size + sizeDelta),
            ),
          );
        }

        // Update root stats for size change
        final root = await (db.select(db.driftRoot)
              ..where((r) => r.id.equals(0)))
            .getSingle();
        await (db.update(db.driftRoot)..where((r) => r.id.equals(0))).write(
          DriftRootCompanion(size: Value(root.size + sizeDelta)),
        );

        if (junction == null) {
          // Add to this store
          await db.into(db.driftStoreTile).insert(
                DriftStoreTileCompanion.insert(
                  store: storeName,
                  tile: url,
                ),
              );
          await (db.update(db.driftStore)
                ..where((s) => s.name.equals(storeName)))
              .write(
            DriftStoreCompanion(
              length: Value(store.length + 1),
              size: Value(store.size + bytes.lengthInBytes),
            ),
          );
        }

        // Update tile bytes
        await (db.update(db.driftTile)..where((t) => t.uid.equals(url))).write(
          DriftTileCompanion(
            bytes: Value(bytes),
            lastModified: Value(DateTime.timestamp()),
          ),
        );
      } else {
        // New tile
        await db.into(db.driftTile).insert(
              DriftTileCompanion.insert(
                uid: url,
                bytes: bytes,
              ),
            );
        await db.into(db.driftStoreTile).insert(
              DriftStoreTileCompanion.insert(
                store: storeName,
                tile: url,
              ),
            );
        await (db.update(db.driftStore)..where((s) => s.name.equals(storeName)))
            .write(
          DriftStoreCompanion(
            length: Value(store.length + 1),
            size: Value(store.size + bytes.lengthInBytes),
          ),
        );

        // Update root stats
        final root = await (db.select(db.driftRoot)
              ..where((r) => r.id.equals(0)))
            .getSingle();
        await (db.update(db.driftRoot)..where((r) => r.id.equals(0))).write(
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
    final db = _expectDb;

    await db.transaction(() async {
      for (int i = 0; i < urls.length; i++) {
        await writeTile(
          storeName: storeName,
          url: urls[i],
          bytes: bytess[i],
        );
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
    final db = _expectDb;

    await db.transaction(() async {
      // Insert recovery entry
      await db.into(db.driftRecovery).insert(
            DriftRecoveryCompanion.insert(
              id: Value(id),
              store: storeName,
              minZoom: region.minZoom,
              maxZoom: region.maxZoom,
              startTile: region.start,
              endTile: region.end ?? (region.start - 1 + tilesCount),
            ),
          );

      // Recursively insert recovery regions
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
            await db.into(db.driftRecoveryRegion).insert(companion);

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
    final db = _expectDb;

    await (db.update(db.driftRecovery)..where((r) => r.id.equals(id)))
        .write(DriftRecoveryCompanion(startTile: Value(newStartTile)));
  }
}
