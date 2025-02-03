// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery_region.drift.dart'
    as i1;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery_region.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/recovery.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;

typedef $$DriftRecoveryRegionTableCreateCompanionBuilder
    = i1.DriftRecoveryRegionCompanion Function({
  i0.Value<int> id,
  required int recovery,
  required int typeId,
  i0.Value<double?> rectNwLat,
  i0.Value<double?> rectNwLng,
  i0.Value<double?> rectSeLat,
  i0.Value<double?> rectSeLng,
  i0.Value<double?> circleCenterLat,
  i0.Value<double?> circleCenterLng,
  i0.Value<double?> circleRadius,
  i0.Value<String?> lineLats,
  i0.Value<String?> lineLngs,
  i0.Value<double?> lineRadius,
  i0.Value<String?> customPolygonLats,
  i0.Value<String?> customPolygonLngs,
});
typedef $$DriftRecoveryRegionTableUpdateCompanionBuilder
    = i1.DriftRecoveryRegionCompanion Function({
  i0.Value<int> id,
  i0.Value<int> recovery,
  i0.Value<int> typeId,
  i0.Value<double?> rectNwLat,
  i0.Value<double?> rectNwLng,
  i0.Value<double?> rectSeLat,
  i0.Value<double?> rectSeLng,
  i0.Value<double?> circleCenterLat,
  i0.Value<double?> circleCenterLng,
  i0.Value<double?> circleRadius,
  i0.Value<String?> lineLats,
  i0.Value<String?> lineLngs,
  i0.Value<double?> lineRadius,
  i0.Value<String?> customPolygonLats,
  i0.Value<String?> customPolygonLngs,
});

final class $$DriftRecoveryRegionTableReferences extends i0.BaseReferences<
    i0.GeneratedDatabase,
    i1.$DriftRecoveryRegionTable,
    i1.DriftRecoveryRegionData> {
  $$DriftRecoveryRegionTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static i4.$DriftRecoveryTable _recoveryTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$DriftRecoveryTable>('drift_recovery')
          .createAlias(i0.$_aliasNameGenerator(
              i5.ReadDatabaseContainer(db)
                  .resultSet<i1.$DriftRecoveryRegionTable>(
                      'drift_recovery_region')
                  .recovery,
              i5.ReadDatabaseContainer(db)
                  .resultSet<i4.$DriftRecoveryTable>('drift_recovery')
                  .id));

  i4.$$DriftRecoveryTableProcessedTableManager get recovery {
    final $_column = $_itemColumn<int>('recovery')!;

    final manager = i4
        .$$DriftRecoveryTableTableManager(
            $_db,
            i5.ReadDatabaseContainer($_db)
                .resultSet<i4.$DriftRecoveryTable>('drift_recovery'))
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recoveryTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DriftRecoveryRegionTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRecoveryRegionTable> {
  $$DriftRecoveryRegionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get rectNwLat => $composableBuilder(
      column: $table.rectNwLat, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get rectNwLng => $composableBuilder(
      column: $table.rectNwLng, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get rectSeLat => $composableBuilder(
      column: $table.rectSeLat, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get rectSeLng => $composableBuilder(
      column: $table.rectSeLng, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get circleCenterLat => $composableBuilder(
      column: $table.circleCenterLat,
      builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get circleCenterLng => $composableBuilder(
      column: $table.circleCenterLng,
      builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get circleRadius => $composableBuilder(
      column: $table.circleRadius,
      builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<String> get lineLats => $composableBuilder(
      column: $table.lineLats, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<String> get lineLngs => $composableBuilder(
      column: $table.lineLngs, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<double> get lineRadius => $composableBuilder(
      column: $table.lineRadius, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<String> get customPolygonLats => $composableBuilder(
      column: $table.customPolygonLats,
      builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<String> get customPolygonLngs => $composableBuilder(
      column: $table.customPolygonLngs,
      builder: (column) => i0.ColumnFilters(column));

  i4.$$DriftRecoveryTableFilterComposer get recovery {
    final i4.$$DriftRecoveryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recovery,
        referencedTable: i5.ReadDatabaseContainer($db)
            .resultSet<i4.$DriftRecoveryTable>('drift_recovery'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i4.$$DriftRecoveryTableFilterComposer(
              $db: $db,
              $table: i5.ReadDatabaseContainer($db)
                  .resultSet<i4.$DriftRecoveryTable>('drift_recovery'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftRecoveryRegionTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRecoveryRegionTable> {
  $$DriftRecoveryRegionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get typeId => $composableBuilder(
      column: $table.typeId, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get rectNwLat => $composableBuilder(
      column: $table.rectNwLat,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get rectNwLng => $composableBuilder(
      column: $table.rectNwLng,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get rectSeLat => $composableBuilder(
      column: $table.rectSeLat,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get rectSeLng => $composableBuilder(
      column: $table.rectSeLng,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get circleCenterLat => $composableBuilder(
      column: $table.circleCenterLat,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get circleCenterLng => $composableBuilder(
      column: $table.circleCenterLng,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get circleRadius => $composableBuilder(
      column: $table.circleRadius,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<String> get lineLats => $composableBuilder(
      column: $table.lineLats, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<String> get lineLngs => $composableBuilder(
      column: $table.lineLngs, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<double> get lineRadius => $composableBuilder(
      column: $table.lineRadius,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<String> get customPolygonLats => $composableBuilder(
      column: $table.customPolygonLats,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<String> get customPolygonLngs => $composableBuilder(
      column: $table.customPolygonLngs,
      builder: (column) => i0.ColumnOrderings(column));

  i4.$$DriftRecoveryTableOrderingComposer get recovery {
    final i4.$$DriftRecoveryTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recovery,
        referencedTable: i5.ReadDatabaseContainer($db)
            .resultSet<i4.$DriftRecoveryTable>('drift_recovery'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i4.$$DriftRecoveryTableOrderingComposer(
              $db: $db,
              $table: i5.ReadDatabaseContainer($db)
                  .resultSet<i4.$DriftRecoveryTable>('drift_recovery'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftRecoveryRegionTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRecoveryRegionTable> {
  $$DriftRecoveryRegionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<int> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  i0.GeneratedColumn<double> get rectNwLat =>
      $composableBuilder(column: $table.rectNwLat, builder: (column) => column);

  i0.GeneratedColumn<double> get rectNwLng =>
      $composableBuilder(column: $table.rectNwLng, builder: (column) => column);

  i0.GeneratedColumn<double> get rectSeLat =>
      $composableBuilder(column: $table.rectSeLat, builder: (column) => column);

  i0.GeneratedColumn<double> get rectSeLng =>
      $composableBuilder(column: $table.rectSeLng, builder: (column) => column);

  i0.GeneratedColumn<double> get circleCenterLat => $composableBuilder(
      column: $table.circleCenterLat, builder: (column) => column);

  i0.GeneratedColumn<double> get circleCenterLng => $composableBuilder(
      column: $table.circleCenterLng, builder: (column) => column);

  i0.GeneratedColumn<double> get circleRadius => $composableBuilder(
      column: $table.circleRadius, builder: (column) => column);

  i0.GeneratedColumn<String> get lineLats =>
      $composableBuilder(column: $table.lineLats, builder: (column) => column);

  i0.GeneratedColumn<String> get lineLngs =>
      $composableBuilder(column: $table.lineLngs, builder: (column) => column);

  i0.GeneratedColumn<double> get lineRadius => $composableBuilder(
      column: $table.lineRadius, builder: (column) => column);

  i0.GeneratedColumn<String> get customPolygonLats => $composableBuilder(
      column: $table.customPolygonLats, builder: (column) => column);

  i0.GeneratedColumn<String> get customPolygonLngs => $composableBuilder(
      column: $table.customPolygonLngs, builder: (column) => column);

  i4.$$DriftRecoveryTableAnnotationComposer get recovery {
    final i4.$$DriftRecoveryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recovery,
        referencedTable: i5.ReadDatabaseContainer($db)
            .resultSet<i4.$DriftRecoveryTable>('drift_recovery'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            i4.$$DriftRecoveryTableAnnotationComposer(
              $db: $db,
              $table: i5.ReadDatabaseContainer($db)
                  .resultSet<i4.$DriftRecoveryTable>('drift_recovery'),
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftRecoveryRegionTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$DriftRecoveryRegionTable,
    i1.DriftRecoveryRegionData,
    i1.$$DriftRecoveryRegionTableFilterComposer,
    i1.$$DriftRecoveryRegionTableOrderingComposer,
    i1.$$DriftRecoveryRegionTableAnnotationComposer,
    $$DriftRecoveryRegionTableCreateCompanionBuilder,
    $$DriftRecoveryRegionTableUpdateCompanionBuilder,
    (i1.DriftRecoveryRegionData, i1.$$DriftRecoveryRegionTableReferences),
    i1.DriftRecoveryRegionData,
    i0.PrefetchHooks Function({bool recovery})> {
  $$DriftRecoveryRegionTableTableManager(
      i0.GeneratedDatabase db, i1.$DriftRecoveryRegionTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => i1
              .$$DriftRecoveryRegionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DriftRecoveryRegionTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$DriftRecoveryRegionTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<int> recovery = const i0.Value.absent(),
            i0.Value<int> typeId = const i0.Value.absent(),
            i0.Value<double?> rectNwLat = const i0.Value.absent(),
            i0.Value<double?> rectNwLng = const i0.Value.absent(),
            i0.Value<double?> rectSeLat = const i0.Value.absent(),
            i0.Value<double?> rectSeLng = const i0.Value.absent(),
            i0.Value<double?> circleCenterLat = const i0.Value.absent(),
            i0.Value<double?> circleCenterLng = const i0.Value.absent(),
            i0.Value<double?> circleRadius = const i0.Value.absent(),
            i0.Value<String?> lineLats = const i0.Value.absent(),
            i0.Value<String?> lineLngs = const i0.Value.absent(),
            i0.Value<double?> lineRadius = const i0.Value.absent(),
            i0.Value<String?> customPolygonLats = const i0.Value.absent(),
            i0.Value<String?> customPolygonLngs = const i0.Value.absent(),
          }) =>
              i1.DriftRecoveryRegionCompanion(
            id: id,
            recovery: recovery,
            typeId: typeId,
            rectNwLat: rectNwLat,
            rectNwLng: rectNwLng,
            rectSeLat: rectSeLat,
            rectSeLng: rectSeLng,
            circleCenterLat: circleCenterLat,
            circleCenterLng: circleCenterLng,
            circleRadius: circleRadius,
            lineLats: lineLats,
            lineLngs: lineLngs,
            lineRadius: lineRadius,
            customPolygonLats: customPolygonLats,
            customPolygonLngs: customPolygonLngs,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required int recovery,
            required int typeId,
            i0.Value<double?> rectNwLat = const i0.Value.absent(),
            i0.Value<double?> rectNwLng = const i0.Value.absent(),
            i0.Value<double?> rectSeLat = const i0.Value.absent(),
            i0.Value<double?> rectSeLng = const i0.Value.absent(),
            i0.Value<double?> circleCenterLat = const i0.Value.absent(),
            i0.Value<double?> circleCenterLng = const i0.Value.absent(),
            i0.Value<double?> circleRadius = const i0.Value.absent(),
            i0.Value<String?> lineLats = const i0.Value.absent(),
            i0.Value<String?> lineLngs = const i0.Value.absent(),
            i0.Value<double?> lineRadius = const i0.Value.absent(),
            i0.Value<String?> customPolygonLats = const i0.Value.absent(),
            i0.Value<String?> customPolygonLngs = const i0.Value.absent(),
          }) =>
              i1.DriftRecoveryRegionCompanion.insert(
            id: id,
            recovery: recovery,
            typeId: typeId,
            rectNwLat: rectNwLat,
            rectNwLng: rectNwLng,
            rectSeLat: rectSeLat,
            rectSeLng: rectSeLng,
            circleCenterLat: circleCenterLat,
            circleCenterLng: circleCenterLng,
            circleRadius: circleRadius,
            lineLats: lineLats,
            lineLngs: lineLngs,
            lineRadius: lineRadius,
            customPolygonLats: customPolygonLats,
            customPolygonLngs: customPolygonLngs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    i1.$$DriftRecoveryRegionTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recovery = false}) {
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
                if (recovery) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recovery,
                    referencedTable: i1.$$DriftRecoveryRegionTableReferences
                        ._recoveryTable(db),
                    referencedColumn: i1.$$DriftRecoveryRegionTableReferences
                        ._recoveryTable(db)
                        .id,
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

typedef $$DriftRecoveryRegionTableProcessedTableManager
    = i0.ProcessedTableManager<
        i0.GeneratedDatabase,
        i1.$DriftRecoveryRegionTable,
        i1.DriftRecoveryRegionData,
        i1.$$DriftRecoveryRegionTableFilterComposer,
        i1.$$DriftRecoveryRegionTableOrderingComposer,
        i1.$$DriftRecoveryRegionTableAnnotationComposer,
        $$DriftRecoveryRegionTableCreateCompanionBuilder,
        $$DriftRecoveryRegionTableUpdateCompanionBuilder,
        (i1.DriftRecoveryRegionData, i1.$$DriftRecoveryRegionTableReferences),
        i1.DriftRecoveryRegionData,
        i0.PrefetchHooks Function({bool recovery})>;

class $DriftRecoveryRegionTable extends i2.DriftRecoveryRegion
    with i0.TableInfo<$DriftRecoveryRegionTable, i1.DriftRecoveryRegionData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftRecoveryRegionTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _recoveryMeta =
      const i0.VerificationMeta('recovery');
  @override
  late final i0.GeneratedColumn<int> recovery = i0.GeneratedColumn<int>(
      'recovery', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
          'REFERENCES drift_recovery (id)'));
  static const i0.VerificationMeta _typeIdMeta =
      const i0.VerificationMeta('typeId');
  @override
  late final i0.GeneratedColumn<int> typeId = i0.GeneratedColumn<int>(
      'type_id', aliasedName, false,
      check: () => i3.ComparableExpr(typeId).isBetweenValues(0, 3),
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true);
  static const i0.VerificationMeta _rectNwLatMeta =
      const i0.VerificationMeta('rectNwLat');
  @override
  late final i0.GeneratedColumn<double> rectNwLat = i0.GeneratedColumn<double>(
      'rect_nw_lat', aliasedName, true,
      type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _rectNwLngMeta =
      const i0.VerificationMeta('rectNwLng');
  @override
  late final i0.GeneratedColumn<double> rectNwLng = i0.GeneratedColumn<double>(
      'rect_nw_lng', aliasedName, true,
      type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _rectSeLatMeta =
      const i0.VerificationMeta('rectSeLat');
  @override
  late final i0.GeneratedColumn<double> rectSeLat = i0.GeneratedColumn<double>(
      'rect_se_lat', aliasedName, true,
      type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _rectSeLngMeta =
      const i0.VerificationMeta('rectSeLng');
  @override
  late final i0.GeneratedColumn<double> rectSeLng = i0.GeneratedColumn<double>(
      'rect_se_lng', aliasedName, true,
      type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _circleCenterLatMeta =
      const i0.VerificationMeta('circleCenterLat');
  @override
  late final i0.GeneratedColumn<double> circleCenterLat =
      i0.GeneratedColumn<double>('circle_center_lat', aliasedName, true,
          type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _circleCenterLngMeta =
      const i0.VerificationMeta('circleCenterLng');
  @override
  late final i0.GeneratedColumn<double> circleCenterLng =
      i0.GeneratedColumn<double>('circle_center_lng', aliasedName, true,
          type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _circleRadiusMeta =
      const i0.VerificationMeta('circleRadius');
  @override
  late final i0.GeneratedColumn<double> circleRadius =
      i0.GeneratedColumn<double>('circle_radius', aliasedName, true,
          type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _lineLatsMeta =
      const i0.VerificationMeta('lineLats');
  @override
  late final i0.GeneratedColumn<String> lineLats = i0.GeneratedColumn<String>(
      'line_lats', aliasedName, true,
      type: i0.DriftSqlType.string, requiredDuringInsert: false);
  static const i0.VerificationMeta _lineLngsMeta =
      const i0.VerificationMeta('lineLngs');
  @override
  late final i0.GeneratedColumn<String> lineLngs = i0.GeneratedColumn<String>(
      'line_lngs', aliasedName, true,
      type: i0.DriftSqlType.string, requiredDuringInsert: false);
  static const i0.VerificationMeta _lineRadiusMeta =
      const i0.VerificationMeta('lineRadius');
  @override
  late final i0.GeneratedColumn<double> lineRadius = i0.GeneratedColumn<double>(
      'line_radius', aliasedName, true,
      type: i0.DriftSqlType.double, requiredDuringInsert: false);
  static const i0.VerificationMeta _customPolygonLatsMeta =
      const i0.VerificationMeta('customPolygonLats');
  @override
  late final i0.GeneratedColumn<String> customPolygonLats =
      i0.GeneratedColumn<String>('custom_polygon_lats', aliasedName, true,
          type: i0.DriftSqlType.string, requiredDuringInsert: false);
  static const i0.VerificationMeta _customPolygonLngsMeta =
      const i0.VerificationMeta('customPolygonLngs');
  @override
  late final i0.GeneratedColumn<String> customPolygonLngs =
      i0.GeneratedColumn<String>('custom_polygon_lngs', aliasedName, true,
          type: i0.DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<i0.GeneratedColumn> get $columns => [
        id,
        recovery,
        typeId,
        rectNwLat,
        rectNwLng,
        rectSeLat,
        rectSeLng,
        circleCenterLat,
        circleCenterLng,
        circleRadius,
        lineLats,
        lineLngs,
        lineRadius,
        customPolygonLats,
        customPolygonLngs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_recovery_region';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.DriftRecoveryRegionData> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recovery')) {
      context.handle(_recoveryMeta,
          recovery.isAcceptableOrUnknown(data['recovery']!, _recoveryMeta));
    } else if (isInserting) {
      context.missing(_recoveryMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(_typeIdMeta,
          typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta));
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    if (data.containsKey('rect_nw_lat')) {
      context.handle(
          _rectNwLatMeta,
          rectNwLat.isAcceptableOrUnknown(
              data['rect_nw_lat']!, _rectNwLatMeta));
    }
    if (data.containsKey('rect_nw_lng')) {
      context.handle(
          _rectNwLngMeta,
          rectNwLng.isAcceptableOrUnknown(
              data['rect_nw_lng']!, _rectNwLngMeta));
    }
    if (data.containsKey('rect_se_lat')) {
      context.handle(
          _rectSeLatMeta,
          rectSeLat.isAcceptableOrUnknown(
              data['rect_se_lat']!, _rectSeLatMeta));
    }
    if (data.containsKey('rect_se_lng')) {
      context.handle(
          _rectSeLngMeta,
          rectSeLng.isAcceptableOrUnknown(
              data['rect_se_lng']!, _rectSeLngMeta));
    }
    if (data.containsKey('circle_center_lat')) {
      context.handle(
          _circleCenterLatMeta,
          circleCenterLat.isAcceptableOrUnknown(
              data['circle_center_lat']!, _circleCenterLatMeta));
    }
    if (data.containsKey('circle_center_lng')) {
      context.handle(
          _circleCenterLngMeta,
          circleCenterLng.isAcceptableOrUnknown(
              data['circle_center_lng']!, _circleCenterLngMeta));
    }
    if (data.containsKey('circle_radius')) {
      context.handle(
          _circleRadiusMeta,
          circleRadius.isAcceptableOrUnknown(
              data['circle_radius']!, _circleRadiusMeta));
    }
    if (data.containsKey('line_lats')) {
      context.handle(_lineLatsMeta,
          lineLats.isAcceptableOrUnknown(data['line_lats']!, _lineLatsMeta));
    }
    if (data.containsKey('line_lngs')) {
      context.handle(_lineLngsMeta,
          lineLngs.isAcceptableOrUnknown(data['line_lngs']!, _lineLngsMeta));
    }
    if (data.containsKey('line_radius')) {
      context.handle(
          _lineRadiusMeta,
          lineRadius.isAcceptableOrUnknown(
              data['line_radius']!, _lineRadiusMeta));
    }
    if (data.containsKey('custom_polygon_lats')) {
      context.handle(
          _customPolygonLatsMeta,
          customPolygonLats.isAcceptableOrUnknown(
              data['custom_polygon_lats']!, _customPolygonLatsMeta));
    }
    if (data.containsKey('custom_polygon_lngs')) {
      context.handle(
          _customPolygonLngsMeta,
          customPolygonLngs.isAcceptableOrUnknown(
              data['custom_polygon_lngs']!, _customPolygonLngsMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.DriftRecoveryRegionData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DriftRecoveryRegionData(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      recovery: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}recovery'])!,
      typeId: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}type_id'])!,
      rectNwLat: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.double, data['${effectivePrefix}rect_nw_lat']),
      rectNwLng: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.double, data['${effectivePrefix}rect_nw_lng']),
      rectSeLat: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.double, data['${effectivePrefix}rect_se_lat']),
      rectSeLng: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.double, data['${effectivePrefix}rect_se_lng']),
      circleCenterLat: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.double, data['${effectivePrefix}circle_center_lat']),
      circleCenterLng: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.double, data['${effectivePrefix}circle_center_lng']),
      circleRadius: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.double, data['${effectivePrefix}circle_radius']),
      lineLats: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}line_lats']),
      lineLngs: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}line_lngs']),
      lineRadius: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.double, data['${effectivePrefix}line_radius']),
      customPolygonLats: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.string,
          data['${effectivePrefix}custom_polygon_lats']),
      customPolygonLngs: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.string,
          data['${effectivePrefix}custom_polygon_lngs']),
    );
  }

  @override
  $DriftRecoveryRegionTable createAlias(String alias) {
    return $DriftRecoveryRegionTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class DriftRecoveryRegionData extends i0.DataClass
    implements i0.Insertable<i1.DriftRecoveryRegionData> {
  final int id;
  final int recovery;
  final int typeId;
  final double? rectNwLat;
  final double? rectNwLng;
  final double? rectSeLat;
  final double? rectSeLng;
  final double? circleCenterLat;
  final double? circleCenterLng;
  final double? circleRadius;
  final String? lineLats;
  final String? lineLngs;
  final double? lineRadius;
  final String? customPolygonLats;
  final String? customPolygonLngs;
  const DriftRecoveryRegionData(
      {required this.id,
      required this.recovery,
      required this.typeId,
      this.rectNwLat,
      this.rectNwLng,
      this.rectSeLat,
      this.rectSeLng,
      this.circleCenterLat,
      this.circleCenterLng,
      this.circleRadius,
      this.lineLats,
      this.lineLngs,
      this.lineRadius,
      this.customPolygonLats,
      this.customPolygonLngs});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['recovery'] = i0.Variable<int>(recovery);
    map['type_id'] = i0.Variable<int>(typeId);
    if (!nullToAbsent || rectNwLat != null) {
      map['rect_nw_lat'] = i0.Variable<double>(rectNwLat);
    }
    if (!nullToAbsent || rectNwLng != null) {
      map['rect_nw_lng'] = i0.Variable<double>(rectNwLng);
    }
    if (!nullToAbsent || rectSeLat != null) {
      map['rect_se_lat'] = i0.Variable<double>(rectSeLat);
    }
    if (!nullToAbsent || rectSeLng != null) {
      map['rect_se_lng'] = i0.Variable<double>(rectSeLng);
    }
    if (!nullToAbsent || circleCenterLat != null) {
      map['circle_center_lat'] = i0.Variable<double>(circleCenterLat);
    }
    if (!nullToAbsent || circleCenterLng != null) {
      map['circle_center_lng'] = i0.Variable<double>(circleCenterLng);
    }
    if (!nullToAbsent || circleRadius != null) {
      map['circle_radius'] = i0.Variable<double>(circleRadius);
    }
    if (!nullToAbsent || lineLats != null) {
      map['line_lats'] = i0.Variable<String>(lineLats);
    }
    if (!nullToAbsent || lineLngs != null) {
      map['line_lngs'] = i0.Variable<String>(lineLngs);
    }
    if (!nullToAbsent || lineRadius != null) {
      map['line_radius'] = i0.Variable<double>(lineRadius);
    }
    if (!nullToAbsent || customPolygonLats != null) {
      map['custom_polygon_lats'] = i0.Variable<String>(customPolygonLats);
    }
    if (!nullToAbsent || customPolygonLngs != null) {
      map['custom_polygon_lngs'] = i0.Variable<String>(customPolygonLngs);
    }
    return map;
  }

  i1.DriftRecoveryRegionCompanion toCompanion(bool nullToAbsent) {
    return i1.DriftRecoveryRegionCompanion(
      id: i0.Value(id),
      recovery: i0.Value(recovery),
      typeId: i0.Value(typeId),
      rectNwLat: rectNwLat == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(rectNwLat),
      rectNwLng: rectNwLng == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(rectNwLng),
      rectSeLat: rectSeLat == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(rectSeLat),
      rectSeLng: rectSeLng == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(rectSeLng),
      circleCenterLat: circleCenterLat == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(circleCenterLat),
      circleCenterLng: circleCenterLng == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(circleCenterLng),
      circleRadius: circleRadius == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(circleRadius),
      lineLats: lineLats == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lineLats),
      lineLngs: lineLngs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lineLngs),
      lineRadius: lineRadius == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lineRadius),
      customPolygonLats: customPolygonLats == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(customPolygonLats),
      customPolygonLngs: customPolygonLngs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(customPolygonLngs),
    );
  }

  factory DriftRecoveryRegionData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DriftRecoveryRegionData(
      id: serializer.fromJson<int>(json['id']),
      recovery: serializer.fromJson<int>(json['recovery']),
      typeId: serializer.fromJson<int>(json['typeId']),
      rectNwLat: serializer.fromJson<double?>(json['rectNwLat']),
      rectNwLng: serializer.fromJson<double?>(json['rectNwLng']),
      rectSeLat: serializer.fromJson<double?>(json['rectSeLat']),
      rectSeLng: serializer.fromJson<double?>(json['rectSeLng']),
      circleCenterLat: serializer.fromJson<double?>(json['circleCenterLat']),
      circleCenterLng: serializer.fromJson<double?>(json['circleCenterLng']),
      circleRadius: serializer.fromJson<double?>(json['circleRadius']),
      lineLats: serializer.fromJson<String?>(json['lineLats']),
      lineLngs: serializer.fromJson<String?>(json['lineLngs']),
      lineRadius: serializer.fromJson<double?>(json['lineRadius']),
      customPolygonLats:
          serializer.fromJson<String?>(json['customPolygonLats']),
      customPolygonLngs:
          serializer.fromJson<String?>(json['customPolygonLngs']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recovery': serializer.toJson<int>(recovery),
      'typeId': serializer.toJson<int>(typeId),
      'rectNwLat': serializer.toJson<double?>(rectNwLat),
      'rectNwLng': serializer.toJson<double?>(rectNwLng),
      'rectSeLat': serializer.toJson<double?>(rectSeLat),
      'rectSeLng': serializer.toJson<double?>(rectSeLng),
      'circleCenterLat': serializer.toJson<double?>(circleCenterLat),
      'circleCenterLng': serializer.toJson<double?>(circleCenterLng),
      'circleRadius': serializer.toJson<double?>(circleRadius),
      'lineLats': serializer.toJson<String?>(lineLats),
      'lineLngs': serializer.toJson<String?>(lineLngs),
      'lineRadius': serializer.toJson<double?>(lineRadius),
      'customPolygonLats': serializer.toJson<String?>(customPolygonLats),
      'customPolygonLngs': serializer.toJson<String?>(customPolygonLngs),
    };
  }

  i1.DriftRecoveryRegionData copyWith(
          {int? id,
          int? recovery,
          int? typeId,
          i0.Value<double?> rectNwLat = const i0.Value.absent(),
          i0.Value<double?> rectNwLng = const i0.Value.absent(),
          i0.Value<double?> rectSeLat = const i0.Value.absent(),
          i0.Value<double?> rectSeLng = const i0.Value.absent(),
          i0.Value<double?> circleCenterLat = const i0.Value.absent(),
          i0.Value<double?> circleCenterLng = const i0.Value.absent(),
          i0.Value<double?> circleRadius = const i0.Value.absent(),
          i0.Value<String?> lineLats = const i0.Value.absent(),
          i0.Value<String?> lineLngs = const i0.Value.absent(),
          i0.Value<double?> lineRadius = const i0.Value.absent(),
          i0.Value<String?> customPolygonLats = const i0.Value.absent(),
          i0.Value<String?> customPolygonLngs = const i0.Value.absent()}) =>
      i1.DriftRecoveryRegionData(
        id: id ?? this.id,
        recovery: recovery ?? this.recovery,
        typeId: typeId ?? this.typeId,
        rectNwLat: rectNwLat.present ? rectNwLat.value : this.rectNwLat,
        rectNwLng: rectNwLng.present ? rectNwLng.value : this.rectNwLng,
        rectSeLat: rectSeLat.present ? rectSeLat.value : this.rectSeLat,
        rectSeLng: rectSeLng.present ? rectSeLng.value : this.rectSeLng,
        circleCenterLat: circleCenterLat.present
            ? circleCenterLat.value
            : this.circleCenterLat,
        circleCenterLng: circleCenterLng.present
            ? circleCenterLng.value
            : this.circleCenterLng,
        circleRadius:
            circleRadius.present ? circleRadius.value : this.circleRadius,
        lineLats: lineLats.present ? lineLats.value : this.lineLats,
        lineLngs: lineLngs.present ? lineLngs.value : this.lineLngs,
        lineRadius: lineRadius.present ? lineRadius.value : this.lineRadius,
        customPolygonLats: customPolygonLats.present
            ? customPolygonLats.value
            : this.customPolygonLats,
        customPolygonLngs: customPolygonLngs.present
            ? customPolygonLngs.value
            : this.customPolygonLngs,
      );
  DriftRecoveryRegionData copyWithCompanion(
      i1.DriftRecoveryRegionCompanion data) {
    return DriftRecoveryRegionData(
      id: data.id.present ? data.id.value : this.id,
      recovery: data.recovery.present ? data.recovery.value : this.recovery,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      rectNwLat: data.rectNwLat.present ? data.rectNwLat.value : this.rectNwLat,
      rectNwLng: data.rectNwLng.present ? data.rectNwLng.value : this.rectNwLng,
      rectSeLat: data.rectSeLat.present ? data.rectSeLat.value : this.rectSeLat,
      rectSeLng: data.rectSeLng.present ? data.rectSeLng.value : this.rectSeLng,
      circleCenterLat: data.circleCenterLat.present
          ? data.circleCenterLat.value
          : this.circleCenterLat,
      circleCenterLng: data.circleCenterLng.present
          ? data.circleCenterLng.value
          : this.circleCenterLng,
      circleRadius: data.circleRadius.present
          ? data.circleRadius.value
          : this.circleRadius,
      lineLats: data.lineLats.present ? data.lineLats.value : this.lineLats,
      lineLngs: data.lineLngs.present ? data.lineLngs.value : this.lineLngs,
      lineRadius:
          data.lineRadius.present ? data.lineRadius.value : this.lineRadius,
      customPolygonLats: data.customPolygonLats.present
          ? data.customPolygonLats.value
          : this.customPolygonLats,
      customPolygonLngs: data.customPolygonLngs.present
          ? data.customPolygonLngs.value
          : this.customPolygonLngs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftRecoveryRegionData(')
          ..write('id: $id, ')
          ..write('recovery: $recovery, ')
          ..write('typeId: $typeId, ')
          ..write('rectNwLat: $rectNwLat, ')
          ..write('rectNwLng: $rectNwLng, ')
          ..write('rectSeLat: $rectSeLat, ')
          ..write('rectSeLng: $rectSeLng, ')
          ..write('circleCenterLat: $circleCenterLat, ')
          ..write('circleCenterLng: $circleCenterLng, ')
          ..write('circleRadius: $circleRadius, ')
          ..write('lineLats: $lineLats, ')
          ..write('lineLngs: $lineLngs, ')
          ..write('lineRadius: $lineRadius, ')
          ..write('customPolygonLats: $customPolygonLats, ')
          ..write('customPolygonLngs: $customPolygonLngs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      recovery,
      typeId,
      rectNwLat,
      rectNwLng,
      rectSeLat,
      rectSeLng,
      circleCenterLat,
      circleCenterLng,
      circleRadius,
      lineLats,
      lineLngs,
      lineRadius,
      customPolygonLats,
      customPolygonLngs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DriftRecoveryRegionData &&
          other.id == this.id &&
          other.recovery == this.recovery &&
          other.typeId == this.typeId &&
          other.rectNwLat == this.rectNwLat &&
          other.rectNwLng == this.rectNwLng &&
          other.rectSeLat == this.rectSeLat &&
          other.rectSeLng == this.rectSeLng &&
          other.circleCenterLat == this.circleCenterLat &&
          other.circleCenterLng == this.circleCenterLng &&
          other.circleRadius == this.circleRadius &&
          other.lineLats == this.lineLats &&
          other.lineLngs == this.lineLngs &&
          other.lineRadius == this.lineRadius &&
          other.customPolygonLats == this.customPolygonLats &&
          other.customPolygonLngs == this.customPolygonLngs);
}

class DriftRecoveryRegionCompanion
    extends i0.UpdateCompanion<i1.DriftRecoveryRegionData> {
  final i0.Value<int> id;
  final i0.Value<int> recovery;
  final i0.Value<int> typeId;
  final i0.Value<double?> rectNwLat;
  final i0.Value<double?> rectNwLng;
  final i0.Value<double?> rectSeLat;
  final i0.Value<double?> rectSeLng;
  final i0.Value<double?> circleCenterLat;
  final i0.Value<double?> circleCenterLng;
  final i0.Value<double?> circleRadius;
  final i0.Value<String?> lineLats;
  final i0.Value<String?> lineLngs;
  final i0.Value<double?> lineRadius;
  final i0.Value<String?> customPolygonLats;
  final i0.Value<String?> customPolygonLngs;
  const DriftRecoveryRegionCompanion({
    this.id = const i0.Value.absent(),
    this.recovery = const i0.Value.absent(),
    this.typeId = const i0.Value.absent(),
    this.rectNwLat = const i0.Value.absent(),
    this.rectNwLng = const i0.Value.absent(),
    this.rectSeLat = const i0.Value.absent(),
    this.rectSeLng = const i0.Value.absent(),
    this.circleCenterLat = const i0.Value.absent(),
    this.circleCenterLng = const i0.Value.absent(),
    this.circleRadius = const i0.Value.absent(),
    this.lineLats = const i0.Value.absent(),
    this.lineLngs = const i0.Value.absent(),
    this.lineRadius = const i0.Value.absent(),
    this.customPolygonLats = const i0.Value.absent(),
    this.customPolygonLngs = const i0.Value.absent(),
  });
  DriftRecoveryRegionCompanion.insert({
    this.id = const i0.Value.absent(),
    required int recovery,
    required int typeId,
    this.rectNwLat = const i0.Value.absent(),
    this.rectNwLng = const i0.Value.absent(),
    this.rectSeLat = const i0.Value.absent(),
    this.rectSeLng = const i0.Value.absent(),
    this.circleCenterLat = const i0.Value.absent(),
    this.circleCenterLng = const i0.Value.absent(),
    this.circleRadius = const i0.Value.absent(),
    this.lineLats = const i0.Value.absent(),
    this.lineLngs = const i0.Value.absent(),
    this.lineRadius = const i0.Value.absent(),
    this.customPolygonLats = const i0.Value.absent(),
    this.customPolygonLngs = const i0.Value.absent(),
  })  : recovery = i0.Value(recovery),
        typeId = i0.Value(typeId);
  static i0.Insertable<i1.DriftRecoveryRegionData> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? recovery,
    i0.Expression<int>? typeId,
    i0.Expression<double>? rectNwLat,
    i0.Expression<double>? rectNwLng,
    i0.Expression<double>? rectSeLat,
    i0.Expression<double>? rectSeLng,
    i0.Expression<double>? circleCenterLat,
    i0.Expression<double>? circleCenterLng,
    i0.Expression<double>? circleRadius,
    i0.Expression<String>? lineLats,
    i0.Expression<String>? lineLngs,
    i0.Expression<double>? lineRadius,
    i0.Expression<String>? customPolygonLats,
    i0.Expression<String>? customPolygonLngs,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (recovery != null) 'recovery': recovery,
      if (typeId != null) 'type_id': typeId,
      if (rectNwLat != null) 'rect_nw_lat': rectNwLat,
      if (rectNwLng != null) 'rect_nw_lng': rectNwLng,
      if (rectSeLat != null) 'rect_se_lat': rectSeLat,
      if (rectSeLng != null) 'rect_se_lng': rectSeLng,
      if (circleCenterLat != null) 'circle_center_lat': circleCenterLat,
      if (circleCenterLng != null) 'circle_center_lng': circleCenterLng,
      if (circleRadius != null) 'circle_radius': circleRadius,
      if (lineLats != null) 'line_lats': lineLats,
      if (lineLngs != null) 'line_lngs': lineLngs,
      if (lineRadius != null) 'line_radius': lineRadius,
      if (customPolygonLats != null) 'custom_polygon_lats': customPolygonLats,
      if (customPolygonLngs != null) 'custom_polygon_lngs': customPolygonLngs,
    });
  }

  i1.DriftRecoveryRegionCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<int>? recovery,
      i0.Value<int>? typeId,
      i0.Value<double?>? rectNwLat,
      i0.Value<double?>? rectNwLng,
      i0.Value<double?>? rectSeLat,
      i0.Value<double?>? rectSeLng,
      i0.Value<double?>? circleCenterLat,
      i0.Value<double?>? circleCenterLng,
      i0.Value<double?>? circleRadius,
      i0.Value<String?>? lineLats,
      i0.Value<String?>? lineLngs,
      i0.Value<double?>? lineRadius,
      i0.Value<String?>? customPolygonLats,
      i0.Value<String?>? customPolygonLngs}) {
    return i1.DriftRecoveryRegionCompanion(
      id: id ?? this.id,
      recovery: recovery ?? this.recovery,
      typeId: typeId ?? this.typeId,
      rectNwLat: rectNwLat ?? this.rectNwLat,
      rectNwLng: rectNwLng ?? this.rectNwLng,
      rectSeLat: rectSeLat ?? this.rectSeLat,
      rectSeLng: rectSeLng ?? this.rectSeLng,
      circleCenterLat: circleCenterLat ?? this.circleCenterLat,
      circleCenterLng: circleCenterLng ?? this.circleCenterLng,
      circleRadius: circleRadius ?? this.circleRadius,
      lineLats: lineLats ?? this.lineLats,
      lineLngs: lineLngs ?? this.lineLngs,
      lineRadius: lineRadius ?? this.lineRadius,
      customPolygonLats: customPolygonLats ?? this.customPolygonLats,
      customPolygonLngs: customPolygonLngs ?? this.customPolygonLngs,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (recovery.present) {
      map['recovery'] = i0.Variable<int>(recovery.value);
    }
    if (typeId.present) {
      map['type_id'] = i0.Variable<int>(typeId.value);
    }
    if (rectNwLat.present) {
      map['rect_nw_lat'] = i0.Variable<double>(rectNwLat.value);
    }
    if (rectNwLng.present) {
      map['rect_nw_lng'] = i0.Variable<double>(rectNwLng.value);
    }
    if (rectSeLat.present) {
      map['rect_se_lat'] = i0.Variable<double>(rectSeLat.value);
    }
    if (rectSeLng.present) {
      map['rect_se_lng'] = i0.Variable<double>(rectSeLng.value);
    }
    if (circleCenterLat.present) {
      map['circle_center_lat'] = i0.Variable<double>(circleCenterLat.value);
    }
    if (circleCenterLng.present) {
      map['circle_center_lng'] = i0.Variable<double>(circleCenterLng.value);
    }
    if (circleRadius.present) {
      map['circle_radius'] = i0.Variable<double>(circleRadius.value);
    }
    if (lineLats.present) {
      map['line_lats'] = i0.Variable<String>(lineLats.value);
    }
    if (lineLngs.present) {
      map['line_lngs'] = i0.Variable<String>(lineLngs.value);
    }
    if (lineRadius.present) {
      map['line_radius'] = i0.Variable<double>(lineRadius.value);
    }
    if (customPolygonLats.present) {
      map['custom_polygon_lats'] = i0.Variable<String>(customPolygonLats.value);
    }
    if (customPolygonLngs.present) {
      map['custom_polygon_lngs'] = i0.Variable<String>(customPolygonLngs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftRecoveryRegionCompanion(')
          ..write('id: $id, ')
          ..write('recovery: $recovery, ')
          ..write('typeId: $typeId, ')
          ..write('rectNwLat: $rectNwLat, ')
          ..write('rectNwLng: $rectNwLng, ')
          ..write('rectSeLat: $rectSeLat, ')
          ..write('rectSeLng: $rectSeLng, ')
          ..write('circleCenterLat: $circleCenterLat, ')
          ..write('circleCenterLng: $circleCenterLng, ')
          ..write('circleRadius: $circleRadius, ')
          ..write('lineLats: $lineLats, ')
          ..write('lineLngs: $lineLngs, ')
          ..write('lineRadius: $lineRadius, ')
          ..write('customPolygonLats: $customPolygonLats, ')
          ..write('customPolygonLngs: $customPolygonLngs')
          ..write(')'))
        .toString();
  }
}
