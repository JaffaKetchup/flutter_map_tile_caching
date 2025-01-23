// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery.drift.dart'
    as i1;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;

typedef $$DriftRecoveryTableCreateCompanionBuilder = i1.DriftRecoveryCompanion
    Function({
  i0.Value<int> id,
  required String store,
  i0.Value<DateTime> creationTime,
  required int minZoom,
  required int maxZoom,
  required int startTile,
  required int endTile,
});
typedef $$DriftRecoveryTableUpdateCompanionBuilder = i1.DriftRecoveryCompanion
    Function({
  i0.Value<int> id,
  i0.Value<String> store,
  i0.Value<DateTime> creationTime,
  i0.Value<int> minZoom,
  i0.Value<int> maxZoom,
  i0.Value<int> startTile,
  i0.Value<int> endTile,
});

final class $$DriftRecoveryTableReferences extends i0.BaseReferences<
    i0.GeneratedDatabase, i1.$DriftRecoveryTable, i1.DriftRecoveryData> {
  $$DriftRecoveryTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static i4.$DriftStoreTable _storeTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$DriftStoreTable>('drift_store')
          .createAlias(i0.$_aliasNameGenerator(
              i5.ReadDatabaseContainer(db)
                  .resultSet<i1.$DriftRecoveryTable>('drift_recovery')
                  .store,
              i5.ReadDatabaseContainer(db)
                  .resultSet<i4.$DriftStoreTable>('drift_store')
                  .name));

  i4.$$DriftStoreTableProcessedTableManager get store {
    final $_column = $_itemColumn<String>('store')!;

    final manager = i4
        .$$DriftStoreTableTableManager(
            $_db,
            i5.ReadDatabaseContainer($_db)
                .resultSet<i4.$DriftStoreTable>('drift_store'))
        .filter((f) => f.name.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DriftRecoveryTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRecoveryTable> {
  $$DriftRecoveryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<DateTime> get creationTime => $composableBuilder(
      column: $table.creationTime,
      builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get startTile => $composableBuilder(
      column: $table.startTile, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get endTile => $composableBuilder(
      column: $table.endTile, builder: (column) => i0.ColumnFilters(column));

  i4.$$DriftStoreTableFilterComposer get store {
    final i4.$$DriftStoreTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: i5.ReadDatabaseContainer($db)
            .resultSet<i4.$DriftStoreTable>('drift_store'),
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i4.$$DriftStoreTableFilterComposer(
              $db: $db,
              $table: i5.ReadDatabaseContainer($db)
                  .resultSet<i4.$DriftStoreTable>('drift_store'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftRecoveryTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRecoveryTable> {
  $$DriftRecoveryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<DateTime> get creationTime => $composableBuilder(
      column: $table.creationTime,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get startTile => $composableBuilder(
      column: $table.startTile,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get endTile => $composableBuilder(
      column: $table.endTile, builder: (column) => i0.ColumnOrderings(column));

  i4.$$DriftStoreTableOrderingComposer get store {
    final i4.$$DriftStoreTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: i5.ReadDatabaseContainer($db)
            .resultSet<i4.$DriftStoreTable>('drift_store'),
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i4.$$DriftStoreTableOrderingComposer(
              $db: $db,
              $table: i5.ReadDatabaseContainer($db)
                  .resultSet<i4.$DriftStoreTable>('drift_store'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftRecoveryTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRecoveryTable> {
  $$DriftRecoveryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get creationTime => $composableBuilder(
      column: $table.creationTime, builder: (column) => column);

  i0.GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  i0.GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  i0.GeneratedColumn<int> get startTile =>
      $composableBuilder(column: $table.startTile, builder: (column) => column);

  i0.GeneratedColumn<int> get endTile =>
      $composableBuilder(column: $table.endTile, builder: (column) => column);

  i4.$$DriftStoreTableAnnotationComposer get store {
    final i4.$$DriftStoreTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: i5.ReadDatabaseContainer($db)
            .resultSet<i4.$DriftStoreTable>('drift_store'),
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i4.$$DriftStoreTableAnnotationComposer(
              $db: $db,
              $table: i5.ReadDatabaseContainer($db)
                  .resultSet<i4.$DriftStoreTable>('drift_store'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftRecoveryTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$DriftRecoveryTable,
    i1.DriftRecoveryData,
    i1.$$DriftRecoveryTableFilterComposer,
    i1.$$DriftRecoveryTableOrderingComposer,
    i1.$$DriftRecoveryTableAnnotationComposer,
    $$DriftRecoveryTableCreateCompanionBuilder,
    $$DriftRecoveryTableUpdateCompanionBuilder,
    (i1.DriftRecoveryData, i1.$$DriftRecoveryTableReferences),
    i1.DriftRecoveryData,
    i0.PrefetchHooks Function({bool store})> {
  $$DriftRecoveryTableTableManager(
      i0.GeneratedDatabase db, i1.$DriftRecoveryTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$DriftRecoveryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DriftRecoveryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$DriftRecoveryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<String> store = const i0.Value.absent(),
            i0.Value<DateTime> creationTime = const i0.Value.absent(),
            i0.Value<int> minZoom = const i0.Value.absent(),
            i0.Value<int> maxZoom = const i0.Value.absent(),
            i0.Value<int> startTile = const i0.Value.absent(),
            i0.Value<int> endTile = const i0.Value.absent(),
          }) =>
              i1.DriftRecoveryCompanion(
            id: id,
            store: store,
            creationTime: creationTime,
            minZoom: minZoom,
            maxZoom: maxZoom,
            startTile: startTile,
            endTile: endTile,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required String store,
            i0.Value<DateTime> creationTime = const i0.Value.absent(),
            required int minZoom,
            required int maxZoom,
            required int startTile,
            required int endTile,
          }) =>
              i1.DriftRecoveryCompanion.insert(
            id: id,
            store: store,
            creationTime: creationTime,
            minZoom: minZoom,
            maxZoom: maxZoom,
            startTile: startTile,
            endTile: endTile,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    i1.$$DriftRecoveryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({store = false}) {
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
                        i1.$$DriftRecoveryTableReferences._storeTable(db),
                    referencedColumn:
                        i1.$$DriftRecoveryTableReferences._storeTable(db).name,
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

typedef $$DriftRecoveryTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$DriftRecoveryTable,
    i1.DriftRecoveryData,
    i1.$$DriftRecoveryTableFilterComposer,
    i1.$$DriftRecoveryTableOrderingComposer,
    i1.$$DriftRecoveryTableAnnotationComposer,
    $$DriftRecoveryTableCreateCompanionBuilder,
    $$DriftRecoveryTableUpdateCompanionBuilder,
    (i1.DriftRecoveryData, i1.$$DriftRecoveryTableReferences),
    i1.DriftRecoveryData,
    i0.PrefetchHooks Function({bool store})>;

class $DriftRecoveryTable extends i2.DriftRecovery
    with i0.TableInfo<$DriftRecoveryTable, i1.DriftRecoveryData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftRecoveryTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      type: i0.DriftSqlType.int, requiredDuringInsert: false);
  static const i0.VerificationMeta _storeMeta =
      const i0.VerificationMeta('store');
  @override
  late final i0.GeneratedColumn<String> store = i0.GeneratedColumn<String>(
      'store', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
          'REFERENCES drift_store (name)'));
  static const i0.VerificationMeta _creationTimeMeta =
      const i0.VerificationMeta('creationTime');
  @override
  late final i0.GeneratedColumn<DateTime> creationTime =
      i0.GeneratedColumn<DateTime>('creation_time', aliasedName, false,
          type: i0.DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: i3.currentDateAndTime);
  static const i0.VerificationMeta _minZoomMeta =
      const i0.VerificationMeta('minZoom');
  @override
  late final i0.GeneratedColumn<int> minZoom = i0.GeneratedColumn<int>(
      'min_zoom', aliasedName, false,
      type: i0.DriftSqlType.int, requiredDuringInsert: true);
  static const i0.VerificationMeta _maxZoomMeta =
      const i0.VerificationMeta('maxZoom');
  @override
  late final i0.GeneratedColumn<int> maxZoom = i0.GeneratedColumn<int>(
      'max_zoom', aliasedName, false,
      type: i0.DriftSqlType.int, requiredDuringInsert: true);
  static const i0.VerificationMeta _startTileMeta =
      const i0.VerificationMeta('startTile');
  @override
  late final i0.GeneratedColumn<int> startTile = i0.GeneratedColumn<int>(
      'start_tile', aliasedName, false,
      type: i0.DriftSqlType.int, requiredDuringInsert: true);
  static const i0.VerificationMeta _endTileMeta =
      const i0.VerificationMeta('endTile');
  @override
  late final i0.GeneratedColumn<int> endTile = i0.GeneratedColumn<int>(
      'end_tile', aliasedName, false,
      type: i0.DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<i0.GeneratedColumn> get $columns =>
      [id, store, creationTime, minZoom, maxZoom, startTile, endTile];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_recovery';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.DriftRecoveryData> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store')) {
      context.handle(
          _storeMeta, store.isAcceptableOrUnknown(data['store']!, _storeMeta));
    } else if (isInserting) {
      context.missing(_storeMeta);
    }
    if (data.containsKey('creation_time')) {
      context.handle(
          _creationTimeMeta,
          creationTime.isAcceptableOrUnknown(
              data['creation_time']!, _creationTimeMeta));
    }
    if (data.containsKey('min_zoom')) {
      context.handle(_minZoomMeta,
          minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta));
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(_maxZoomMeta,
          maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta));
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('start_tile')) {
      context.handle(_startTileMeta,
          startTile.isAcceptableOrUnknown(data['start_tile']!, _startTileMeta));
    } else if (isInserting) {
      context.missing(_startTileMeta);
    }
    if (data.containsKey('end_tile')) {
      context.handle(_endTileMeta,
          endTile.isAcceptableOrUnknown(data['end_tile']!, _endTileMeta));
    } else if (isInserting) {
      context.missing(_endTileMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.DriftRecoveryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DriftRecoveryData(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      store: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}store'])!,
      creationTime: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.dateTime, data['${effectivePrefix}creation_time'])!,
      minZoom: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}min_zoom'])!,
      maxZoom: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}max_zoom'])!,
      startTile: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}start_tile'])!,
      endTile: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}end_tile'])!,
    );
  }

  @override
  $DriftRecoveryTable createAlias(String alias) {
    return $DriftRecoveryTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class DriftRecoveryData extends i0.DataClass
    implements i0.Insertable<i1.DriftRecoveryData> {
  final int id;
  final String store;
  final DateTime creationTime;
  final int minZoom;
  final int maxZoom;
  final int startTile;
  final int endTile;
  const DriftRecoveryData(
      {required this.id,
      required this.store,
      required this.creationTime,
      required this.minZoom,
      required this.maxZoom,
      required this.startTile,
      required this.endTile});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['store'] = i0.Variable<String>(store);
    map['creation_time'] = i0.Variable<DateTime>(creationTime);
    map['min_zoom'] = i0.Variable<int>(minZoom);
    map['max_zoom'] = i0.Variable<int>(maxZoom);
    map['start_tile'] = i0.Variable<int>(startTile);
    map['end_tile'] = i0.Variable<int>(endTile);
    return map;
  }

  i1.DriftRecoveryCompanion toCompanion(bool nullToAbsent) {
    return i1.DriftRecoveryCompanion(
      id: i0.Value(id),
      store: i0.Value(store),
      creationTime: i0.Value(creationTime),
      minZoom: i0.Value(minZoom),
      maxZoom: i0.Value(maxZoom),
      startTile: i0.Value(startTile),
      endTile: i0.Value(endTile),
    );
  }

  factory DriftRecoveryData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DriftRecoveryData(
      id: serializer.fromJson<int>(json['id']),
      store: serializer.fromJson<String>(json['store']),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      startTile: serializer.fromJson<int>(json['startTile']),
      endTile: serializer.fromJson<int>(json['endTile']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'store': serializer.toJson<String>(store),
      'creationTime': serializer.toJson<DateTime>(creationTime),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'startTile': serializer.toJson<int>(startTile),
      'endTile': serializer.toJson<int>(endTile),
    };
  }

  i1.DriftRecoveryData copyWith(
          {int? id,
          String? store,
          DateTime? creationTime,
          int? minZoom,
          int? maxZoom,
          int? startTile,
          int? endTile}) =>
      i1.DriftRecoveryData(
        id: id ?? this.id,
        store: store ?? this.store,
        creationTime: creationTime ?? this.creationTime,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        startTile: startTile ?? this.startTile,
        endTile: endTile ?? this.endTile,
      );
  DriftRecoveryData copyWithCompanion(i1.DriftRecoveryCompanion data) {
    return DriftRecoveryData(
      id: data.id.present ? data.id.value : this.id,
      store: data.store.present ? data.store.value : this.store,
      creationTime: data.creationTime.present
          ? data.creationTime.value
          : this.creationTime,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      startTile: data.startTile.present ? data.startTile.value : this.startTile,
      endTile: data.endTile.present ? data.endTile.value : this.endTile,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftRecoveryData(')
          ..write('id: $id, ')
          ..write('store: $store, ')
          ..write('creationTime: $creationTime, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('startTile: $startTile, ')
          ..write('endTile: $endTile')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, store, creationTime, minZoom, maxZoom, startTile, endTile);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DriftRecoveryData &&
          other.id == this.id &&
          other.store == this.store &&
          other.creationTime == this.creationTime &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.startTile == this.startTile &&
          other.endTile == this.endTile);
}

class DriftRecoveryCompanion extends i0.UpdateCompanion<i1.DriftRecoveryData> {
  final i0.Value<int> id;
  final i0.Value<String> store;
  final i0.Value<DateTime> creationTime;
  final i0.Value<int> minZoom;
  final i0.Value<int> maxZoom;
  final i0.Value<int> startTile;
  final i0.Value<int> endTile;
  const DriftRecoveryCompanion({
    this.id = const i0.Value.absent(),
    this.store = const i0.Value.absent(),
    this.creationTime = const i0.Value.absent(),
    this.minZoom = const i0.Value.absent(),
    this.maxZoom = const i0.Value.absent(),
    this.startTile = const i0.Value.absent(),
    this.endTile = const i0.Value.absent(),
  });
  DriftRecoveryCompanion.insert({
    this.id = const i0.Value.absent(),
    required String store,
    this.creationTime = const i0.Value.absent(),
    required int minZoom,
    required int maxZoom,
    required int startTile,
    required int endTile,
  })  : store = i0.Value(store),
        minZoom = i0.Value(minZoom),
        maxZoom = i0.Value(maxZoom),
        startTile = i0.Value(startTile),
        endTile = i0.Value(endTile);
  static i0.Insertable<i1.DriftRecoveryData> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? store,
    i0.Expression<DateTime>? creationTime,
    i0.Expression<int>? minZoom,
    i0.Expression<int>? maxZoom,
    i0.Expression<int>? startTile,
    i0.Expression<int>? endTile,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (store != null) 'store': store,
      if (creationTime != null) 'creation_time': creationTime,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (startTile != null) 'start_tile': startTile,
      if (endTile != null) 'end_tile': endTile,
    });
  }

  i1.DriftRecoveryCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? store,
      i0.Value<DateTime>? creationTime,
      i0.Value<int>? minZoom,
      i0.Value<int>? maxZoom,
      i0.Value<int>? startTile,
      i0.Value<int>? endTile}) {
    return i1.DriftRecoveryCompanion(
      id: id ?? this.id,
      store: store ?? this.store,
      creationTime: creationTime ?? this.creationTime,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      startTile: startTile ?? this.startTile,
      endTile: endTile ?? this.endTile,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (store.present) {
      map['store'] = i0.Variable<String>(store.value);
    }
    if (creationTime.present) {
      map['creation_time'] = i0.Variable<DateTime>(creationTime.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = i0.Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = i0.Variable<int>(maxZoom.value);
    }
    if (startTile.present) {
      map['start_tile'] = i0.Variable<int>(startTile.value);
    }
    if (endTile.present) {
      map['end_tile'] = i0.Variable<int>(endTile.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftRecoveryCompanion(')
          ..write('id: $id, ')
          ..write('store: $store, ')
          ..write('creationTime: $creationTime, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('startTile: $startTile, ')
          ..write('endTile: $endTile')
          ..write(')'))
        .toString();
  }
}
