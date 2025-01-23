// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store_tile.drift.dart'
    as i1;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store_tile.dart'
    as i2;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store.drift.dart'
    as i3;
import 'package:drift/internal/modular.dart' as i4;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/tile.drift.dart'
    as i5;

typedef $$DriftStoreTileTableCreateCompanionBuilder = i1.DriftStoreTileCompanion
    Function({
  required String store,
  required String tile,
});
typedef $$DriftStoreTileTableUpdateCompanionBuilder = i1.DriftStoreTileCompanion
    Function({
  i0.Value<String> store,
  i0.Value<String> tile,
});

final class $$DriftStoreTileTableReferences extends i0.BaseReferences<
    i0.GeneratedDatabase, i1.$DriftStoreTileTable, i1.DriftStoreTileData> {
  $$DriftStoreTileTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static i3.$DriftStoreTable _storeTable(i0.GeneratedDatabase db) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i3.$DriftStoreTable>('drift_store')
          .createAlias(i0.$_aliasNameGenerator(
              i4.ReadDatabaseContainer(db)
                  .resultSet<i1.$DriftStoreTileTable>('drift_store_tile')
                  .store,
              i4.ReadDatabaseContainer(db)
                  .resultSet<i3.$DriftStoreTable>('drift_store')
                  .name));

  i3.$$DriftStoreTableProcessedTableManager get store {
    final $_column = $_itemColumn<String>('store')!;

    final manager = i3
        .$$DriftStoreTableTableManager(
            $_db,
            i4.ReadDatabaseContainer($_db)
                .resultSet<i3.$DriftStoreTable>('drift_store'))
        .filter((f) => f.name.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static i5.$DriftTileTable _tileTable(i0.GeneratedDatabase db) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i5.$DriftTileTable>('drift_tile')
          .createAlias(i0.$_aliasNameGenerator(
              i4.ReadDatabaseContainer(db)
                  .resultSet<i1.$DriftStoreTileTable>('drift_store_tile')
                  .tile,
              i4.ReadDatabaseContainer(db)
                  .resultSet<i5.$DriftTileTable>('drift_tile')
                  .uid));

  i5.$$DriftTileTableProcessedTableManager get tile {
    final $_column = $_itemColumn<String>('tile')!;

    final manager = i5
        .$$DriftTileTableTableManager(
            $_db,
            i4.ReadDatabaseContainer($_db)
                .resultSet<i5.$DriftTileTable>('drift_tile'))
        .filter((f) => f.uid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tileTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DriftStoreTileTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftStoreTileTable> {
  $$DriftStoreTileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i3.$$DriftStoreTableFilterComposer get store {
    final i3.$$DriftStoreTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: i4.ReadDatabaseContainer($db)
            .resultSet<i3.$DriftStoreTable>('drift_store'),
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i3.$$DriftStoreTableFilterComposer(
              $db: $db,
              $table: i4.ReadDatabaseContainer($db)
                  .resultSet<i3.$DriftStoreTable>('drift_store'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  i5.$$DriftTileTableFilterComposer get tile {
    final i5.$$DriftTileTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tile,
        referencedTable: i4.ReadDatabaseContainer($db)
            .resultSet<i5.$DriftTileTable>('drift_tile'),
        getReferencedColumn: (t) => t.uid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i5.$$DriftTileTableFilterComposer(
              $db: $db,
              $table: i4.ReadDatabaseContainer($db)
                  .resultSet<i5.$DriftTileTable>('drift_tile'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftStoreTileTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftStoreTileTable> {
  $$DriftStoreTileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i3.$$DriftStoreTableOrderingComposer get store {
    final i3.$$DriftStoreTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: i4.ReadDatabaseContainer($db)
            .resultSet<i3.$DriftStoreTable>('drift_store'),
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i3.$$DriftStoreTableOrderingComposer(
              $db: $db,
              $table: i4.ReadDatabaseContainer($db)
                  .resultSet<i3.$DriftStoreTable>('drift_store'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  i5.$$DriftTileTableOrderingComposer get tile {
    final i5.$$DriftTileTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tile,
        referencedTable: i4.ReadDatabaseContainer($db)
            .resultSet<i5.$DriftTileTable>('drift_tile'),
        getReferencedColumn: (t) => t.uid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i5.$$DriftTileTableOrderingComposer(
              $db: $db,
              $table: i4.ReadDatabaseContainer($db)
                  .resultSet<i5.$DriftTileTable>('drift_tile'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftStoreTileTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftStoreTileTable> {
  $$DriftStoreTileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i3.$$DriftStoreTableAnnotationComposer get store {
    final i3.$$DriftStoreTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: i4.ReadDatabaseContainer($db)
            .resultSet<i3.$DriftStoreTable>('drift_store'),
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i3.$$DriftStoreTableAnnotationComposer(
              $db: $db,
              $table: i4.ReadDatabaseContainer($db)
                  .resultSet<i3.$DriftStoreTable>('drift_store'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  i5.$$DriftTileTableAnnotationComposer get tile {
    final i5.$$DriftTileTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tile,
        referencedTable: i4.ReadDatabaseContainer($db)
            .resultSet<i5.$DriftTileTable>('drift_tile'),
        getReferencedColumn: (t) => t.uid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i5.$$DriftTileTableAnnotationComposer(
              $db: $db,
              $table: i4.ReadDatabaseContainer($db)
                  .resultSet<i5.$DriftTileTable>('drift_tile'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftStoreTileTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$DriftStoreTileTable,
    i1.DriftStoreTileData,
    i1.$$DriftStoreTileTableFilterComposer,
    i1.$$DriftStoreTileTableOrderingComposer,
    i1.$$DriftStoreTileTableAnnotationComposer,
    $$DriftStoreTileTableCreateCompanionBuilder,
    $$DriftStoreTileTableUpdateCompanionBuilder,
    (i1.DriftStoreTileData, i1.$$DriftStoreTileTableReferences),
    i1.DriftStoreTileData,
    i0.PrefetchHooks Function({bool store, bool tile})> {
  $$DriftStoreTileTableTableManager(
      i0.GeneratedDatabase db, i1.$DriftStoreTileTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$DriftStoreTileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DriftStoreTileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$DriftStoreTileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<String> store = const i0.Value.absent(),
            i0.Value<String> tile = const i0.Value.absent(),
          }) =>
              i1.DriftStoreTileCompanion(
            store: store,
            tile: tile,
          ),
          createCompanionCallback: ({
            required String store,
            required String tile,
          }) =>
              i1.DriftStoreTileCompanion.insert(
            store: store,
            tile: tile,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    i1.$$DriftStoreTileTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({store = false, tile = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (store) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.store,
                    referencedTable:
                        i1.$$DriftStoreTileTableReferences._storeTable(db),
                    referencedColumn:
                        i1.$$DriftStoreTileTableReferences._storeTable(db).name,
                  ) as T;
                }
                if (tile) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tile,
                    referencedTable:
                        i1.$$DriftStoreTileTableReferences._tileTable(db),
                    referencedColumn:
                        i1.$$DriftStoreTileTableReferences._tileTable(db).uid,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DriftStoreTileTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$DriftStoreTileTable,
    i1.DriftStoreTileData,
    i1.$$DriftStoreTileTableFilterComposer,
    i1.$$DriftStoreTileTableOrderingComposer,
    i1.$$DriftStoreTileTableAnnotationComposer,
    $$DriftStoreTileTableCreateCompanionBuilder,
    $$DriftStoreTileTableUpdateCompanionBuilder,
    (i1.DriftStoreTileData, i1.$$DriftStoreTileTableReferences),
    i1.DriftStoreTileData,
    i0.PrefetchHooks Function({bool store, bool tile})>;

class $DriftStoreTileTable extends i2.DriftStoreTile
    with i0.TableInfo<$DriftStoreTileTable, i1.DriftStoreTileData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftStoreTileTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _storeMeta =
      const i0.VerificationMeta('store');
  @override
  late final i0.GeneratedColumn<String> store = i0.GeneratedColumn<String>(
      'store', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
          'REFERENCES drift_store (name)'));
  static const i0.VerificationMeta _tileMeta =
      const i0.VerificationMeta('tile');
  @override
  late final i0.GeneratedColumn<String> tile = i0.GeneratedColumn<String>(
      'tile', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('REFERENCES drift_tile (uid)'));
  @override
  List<i0.GeneratedColumn> get $columns => [store, tile];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_store_tile';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.DriftStoreTileData> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('store')) {
      context.handle(
          _storeMeta, store.isAcceptableOrUnknown(data['store']!, _storeMeta));
    } else if (isInserting) {
      context.missing(_storeMeta);
    }
    if (data.containsKey('tile')) {
      context.handle(
          _tileMeta, tile.isAcceptableOrUnknown(data['tile']!, _tileMeta));
    } else if (isInserting) {
      context.missing(_tileMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {store, tile};
  @override
  i1.DriftStoreTileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DriftStoreTileData(
      store: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}store'])!,
      tile: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}tile'])!,
    );
  }

  @override
  $DriftStoreTileTable createAlias(String alias) {
    return $DriftStoreTileTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
}

class DriftStoreTileData extends i0.DataClass
    implements i0.Insertable<i1.DriftStoreTileData> {
  final String store;
  final String tile;
  const DriftStoreTileData({required this.store, required this.tile});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['store'] = i0.Variable<String>(store);
    map['tile'] = i0.Variable<String>(tile);
    return map;
  }

  i1.DriftStoreTileCompanion toCompanion(bool nullToAbsent) {
    return i1.DriftStoreTileCompanion(
      store: i0.Value(store),
      tile: i0.Value(tile),
    );
  }

  factory DriftStoreTileData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DriftStoreTileData(
      store: serializer.fromJson<String>(json['store']),
      tile: serializer.fromJson<String>(json['tile']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'store': serializer.toJson<String>(store),
      'tile': serializer.toJson<String>(tile),
    };
  }

  i1.DriftStoreTileData copyWith({String? store, String? tile}) =>
      i1.DriftStoreTileData(
        store: store ?? this.store,
        tile: tile ?? this.tile,
      );
  DriftStoreTileData copyWithCompanion(i1.DriftStoreTileCompanion data) {
    return DriftStoreTileData(
      store: data.store.present ? data.store.value : this.store,
      tile: data.tile.present ? data.tile.value : this.tile,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftStoreTileData(')
          ..write('store: $store, ')
          ..write('tile: $tile')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(store, tile);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DriftStoreTileData &&
          other.store == this.store &&
          other.tile == this.tile);
}

class DriftStoreTileCompanion
    extends i0.UpdateCompanion<i1.DriftStoreTileData> {
  final i0.Value<String> store;
  final i0.Value<String> tile;
  const DriftStoreTileCompanion({
    this.store = const i0.Value.absent(),
    this.tile = const i0.Value.absent(),
  });
  DriftStoreTileCompanion.insert({
    required String store,
    required String tile,
  })  : store = i0.Value(store),
        tile = i0.Value(tile);
  static i0.Insertable<i1.DriftStoreTileData> custom({
    i0.Expression<String>? store,
    i0.Expression<String>? tile,
  }) {
    return i0.RawValuesInsertable({
      if (store != null) 'store': store,
      if (tile != null) 'tile': tile,
    });
  }

  i1.DriftStoreTileCompanion copyWith(
      {i0.Value<String>? store, i0.Value<String>? tile}) {
    return i1.DriftStoreTileCompanion(
      store: store ?? this.store,
      tile: tile ?? this.tile,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (store.present) {
      map['store'] = i0.Variable<String>(store.value);
    }
    if (tile.present) {
      map['tile'] = i0.Variable<String>(tile.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftStoreTileCompanion(')
          ..write('store: $store, ')
          ..write('tile: $tile')
          ..write(')'))
        .toString();
  }
}
