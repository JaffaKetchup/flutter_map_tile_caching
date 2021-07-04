import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart' show Tuple2;

/// Manages caching database using sqflite
class TileStorageCachingManager {
  static TileStorageCachingManager? _instance;

  static const int kDefaultMaxTileAmount = 20000;
  static final int kMaxRefreshRowsCount = 10;
  static final String _kDbName = 'tileStore.db';
  static final String _kTilesTable = 'tiles';
  static final String _kZoomLevelColumn = 'zoom_level';
  static final String _kTileRowColumn = 'tile_row';
  static final String _kTileColumnColumn = 'tile_column';
  static final String _kTileDataColumn = 'tile_data';
  static final String _kUpdateDateColumn = '_lastUpdateColumn';
  static final String _kCacheNameColumn = 'cache_id';
  static final String _kSizeTriggerName = 'size_trigger';

  static final String _kTileCacheConfigTable = 'config';
  static final String _kConfigKeyColumn = 'config_key';
  static final String _kConfigValueColumn = 'config_value';
  static final String _kMaxTileAmountConfig = 'max_tiles_amount_config';
  Database? _db;

  final _lock = Lock();

  static TileStorageCachingManager _getInstance() {
    _instance ??= TileStorageCachingManager._internal();
    return _instance!;
  }

  /// Create an instance of the caching database
  factory TileStorageCachingManager() => _getInstance();

  TileStorageCachingManager._internal();

  Future<Database> get database async {
    if (_db == null) {
      await _lock.synchronized(() async {
        if (_db == null) {
          final path = await _path;
          _db = await openDatabase(
            path,
            version: 1,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          );
        }
      });
    }
    return _db!;
  }

  static Future<String> get _path async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _kDbName);
    await Directory(databasePath).create(recursive: true);
    return path;
  }

  static String _getSizeTriggerQuery(int tileCount,
          {String cacheName = 'mainCache'}) =>
      '''
        CREATE TRIGGER $_kSizeTriggerName 
	      AFTER INSERT on $_kTilesTable
	      WHEN (select count(*) from $_kTilesTable where $_kCacheNameColumn == \'$cacheName\') > $tileCount
	        BEGIN
		        DELETE from $_kTilesTable where $_kUpdateDateColumn <= 
		          (select $_kUpdateDateColumn  from $_kTilesTable 
		            order by $_kUpdateDateColumn asc 
		            LIMIT 1 OFFSET $kMaxRefreshRowsCount) AND $_kCacheNameColumn == \'$cacheName\';
	        END;
      ''';

  Future<void> _onConfigure(Database db) async {}

  Future<void> _onCreate(Database db, int version) async {
    await _createConfigTable(db);
    await _createCacheTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> _createConfigTable(Database db) async {
    final batch = db.batch();
    batch.execute('DROP TABLE IF EXISTS $_kTileCacheConfigTable');
    batch.execute('''
      CREATE TABLE $_kTileCacheConfigTable(
        $_kConfigKeyColumn TEXT NOT NULL,
        $_kConfigValueColumn TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE UNIQUE INDEX idx_config_key
      ON $_kTileCacheConfigTable($_kConfigKeyColumn);
    ''');
    await batch.commit();
  }

  static Future<void> _createCacheTable(Database db,
      {int maxTileAmount = kDefaultMaxTileAmount}) async {
    final batch = db.batch();
    batch.execute('DROP TABLE IF EXISTS $_kTilesTable');
    batch.execute('''
      CREATE TABLE $_kTilesTable(
        $_kZoomLevelColumn INTEGER NOT NULL,
        $_kTileColumnColumn INTEGER NOT NULL,
        $_kTileRowColumn INTEGER NOT NULL,
        $_kTileDataColumn BLOB NOT NULL,
        $_kUpdateDateColumn INTEGER NOT NULL,
        $_kCacheNameColumn TEXT NOT NULL
      )
    ''');
    batch.execute('''
       CREATE UNIQUE INDEX  tile_index ON $_kTilesTable (
         $_kZoomLevelColumn, 
         $_kTileColumnColumn, 
         $_kTileRowColumn,
         $_kCacheNameColumn
       )
    ''');
    batch.execute(_getSizeTriggerQuery(maxTileAmount));
    await batch.commit();
  }

  /// Get local tile by tile index [Coords].
  /// Return [Tuple2], where [Tuple2.item1] is bytes of tile image,
  /// [Tuple2.item2] - last update [DateTime] of this tile.
  static Future<Tuple2<Uint8List, DateTime>?> getTile(Coords coords,
      {String cacheName = 'mainCache'}) async {
    List<Map> result = await (await _getInstance().database).rawQuery(
        'select $_kTileDataColumn, $_kUpdateDateColumn from $_kTilesTable '
        'where $_kZoomLevelColumn = ${coords.z} AND '
        '$_kTileColumnColumn = ${coords.x} AND '
        '$_kTileRowColumn = ${coords.y} AND '
        '$_kCacheNameColumn = \'$cacheName\' limit 1');
    return result.isNotEmpty
        ? Tuple2(
            result.first[_kTileDataColumn],
            DateTime.fromMillisecondsSinceEpoch(
                1000 * result.first[_kUpdateDateColumn] as int))
        : null;
  }

  /// Save tile bytes [tile] with [coords] to local database.
  /// Also saves update timestamp [DateTime.now].
  static Future<void> saveTile(Uint8List tile, Coords coords,
      {String cacheName = 'mainCache'}) async {
    await (await _getInstance().database).insert(
        _kTilesTable,
        {
          _kZoomLevelColumn: coords.z,
          _kTileColumnColumn: coords.x,
          _kTileRowColumn: coords.y,
          _kUpdateDateColumn: (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          _kTileDataColumn: tile,
          _kCacheNameColumn: cacheName
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Change the maximum number of persisted tiles.
  ///
  /// Default value is 20000, and this applies to each cache.
  /// To avoid collisions this method should be called before widget build.
  static Future<void> changeMaxTileAmount(int maxTileAmount) async {
    assert(maxTileAmount > 0, 'maxTileAmount must be bigger then 0');
    final db = await _getInstance().database;
    await db.transaction((txn) async {
      await txn.execute('DROP TRIGGER $_kSizeTriggerName');
      await txn.execute(_getSizeTriggerQuery(maxTileAmount));
      await txn.insert(
          _kTileCacheConfigTable,
          {
            _kConfigKeyColumn: _kMaxTileAmountConfig,
            _kConfigValueColumn: maxTileAmount.toString()
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      List<Map> currentTilesAmountResult =
          await txn.rawQuery('select count(*) from $_kTilesTable');
      final currentTilesAmount = currentTilesAmountResult.isNotEmpty
          ? currentTilesAmountResult.first['count(*)']
          : 0;
      if (currentTilesAmount > maxTileAmount) {
        List<Map> lastValidTileDateResult = await txn
            .rawQuery('select $_kUpdateDateColumn from $_kTilesTable order by'
                ' $_kUpdateDateColumn asc '
                'limit 1 offset ${currentTilesAmount - maxTileAmount}');
        if (lastValidTileDateResult.isEmpty) return;
        final lastValidTileDate =
            lastValidTileDateResult.first[_kUpdateDateColumn];
        if (lastValidTileDate == null) return;
        await txn.delete(_kTilesTable,
            where: '$_kUpdateDateColumn <= ?', whereArgs: [lastValidTileDate]);
      }
    });
  }

  /// Clean all cached tiles without further notice. Not undoable.
  static Future<void> cleanAllCache() async {
    if (!(await isDbFileExists)) return;
    final db = await _getInstance().database;
    final maxTileAmount = await maxCachedTilesAmount;
    await _createCacheTable(db, maxTileAmount: maxTileAmount);
  }

  /// Clean all cached tiles without further notice. Not undoable.
  ///
  /// Deprecated. Use `cleanAllCache()` instead.
  @Deprecated(
      'This function will be removed in the next release. Migrate to the Caches API as soon as possible (see docs).')
  static Future<void> cleanCache() async {
    await cleanAllCache();
  }

  /// Clean all cached tiles under a specific cache name. Not undoable.
  static Future<int> cleanCacheName(String cacheName) async {
    if (!(await isDbFileExists)) return 0;
    final db = await _getInstance().database;
    return await db.delete(_kTilesTable,
        where: '$_kCacheNameColumn == \'$cacheName\'');
  }

  /// [File] with cached tiles db
  static Future<File> get dbFile async => File(await _path);

  /// [bool] flag for [dbFile] existence
  static Future<bool> get isDbFileExists async => (await dbFile).exists();

  /// Get total size of cached tiles in bytes
  ///
  /// Divide by 1049000 for number of MB
  static Future<int> get cacheDbSize async {
    if (!(await isDbFileExists)) return 0;
    return File((await _path)).length();
  }

  /// Get total number of cached tiles
  static Future<int> get cachedTilesAmount async {
    if (!(await isDbFileExists)) return 0;
    final db = await _getInstance().database;
    List<Map> result = await db.rawQuery('select count(*) from $_kTilesTable');
    return result.isNotEmpty ? result.first['count(*)'] : 0;
  }

  /// Get number of cached tiles in a specific cache
  static Future<int> cachedTilesAmountName(String cacheName) async {
    if (!(await isDbFileExists)) return 0;
    final db = await _getInstance().database;
    List<Map> result = await db.rawQuery(
        'select count(*) from $_kTilesTable where $_kCacheNameColumn == \'$cacheName\'');
    return result.isNotEmpty ? result.first['count(*)'] : 0;
  }

  /// Get all the cache names that currently exist
  static Future<List<String>> get allCacheNames async {
    if (!(await isDbFileExists)) return [];
    final db = await _getInstance().database;
    List<Map> result = await db
        .rawQuery('select distinct $_kCacheNameColumn from $_kTilesTable');
    if (result.isNotEmpty) {
      List<String> output = [];
      result.forEach((e) => output.add(e.values.toList()[0]));
      return output;
    }
    return [];
  }

  /// Get current maxCachedTilesAmount
  static Future<int> get maxCachedTilesAmount async {
    if (!(await isDbFileExists)) return kDefaultMaxTileAmount;
    final db = await _getInstance().database;
    List<Map> result = await db.rawQuery(
        'select $_kConfigValueColumn from $_kTileCacheConfigTable where $_kConfigKeyColumn = "$_kMaxTileAmountConfig" limit 1');
    return result.isNotEmpty
        ? int.parse(result.first[_kConfigValueColumn])
        : kDefaultMaxTileAmount;
  }
}
