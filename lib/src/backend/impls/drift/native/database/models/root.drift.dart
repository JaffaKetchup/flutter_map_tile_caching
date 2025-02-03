// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/root.drift.dart'
    as i1;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/root.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;

typedef $$DriftRootTableCreateCompanionBuilder = i1.DriftRootCompanion
    Function({
  i0.Value<int> id,
  i0.Value<int> length,
  i0.Value<int> size,
});
typedef $$DriftRootTableUpdateCompanionBuilder = i1.DriftRootCompanion
    Function({
  i0.Value<int> id,
  i0.Value<int> length,
  i0.Value<int> size,
});

class $$DriftRootTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRootTable> {
  $$DriftRootTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get length => $composableBuilder(
      column: $table.length, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => i0.ColumnFilters(column));
}

class $$DriftRootTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRootTable> {
  $$DriftRootTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get length => $composableBuilder(
      column: $table.length, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => i0.ColumnOrderings(column));
}

class $$DriftRootTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftRootTable> {
  $$DriftRootTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<int> get length =>
      $composableBuilder(column: $table.length, builder: (column) => column);

  i0.GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);
}

class $$DriftRootTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$DriftRootTable,
    i1.DriftRootData,
    i1.$$DriftRootTableFilterComposer,
    i1.$$DriftRootTableOrderingComposer,
    i1.$$DriftRootTableAnnotationComposer,
    $$DriftRootTableCreateCompanionBuilder,
    $$DriftRootTableUpdateCompanionBuilder,
    (
      i1.DriftRootData,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$DriftRootTable,
          i1.DriftRootData>
    ),
    i1.DriftRootData,
    i0.PrefetchHooks Function()> {
  $$DriftRootTableTableManager(
      i0.GeneratedDatabase db, i1.$DriftRootTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$DriftRootTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DriftRootTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$DriftRootTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<int> length = const i0.Value.absent(),
            i0.Value<int> size = const i0.Value.absent(),
          }) =>
              i1.DriftRootCompanion(
            id: id,
            length: length,
            size: size,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<int> length = const i0.Value.absent(),
            i0.Value<int> size = const i0.Value.absent(),
          }) =>
              i1.DriftRootCompanion.insert(
            id: id,
            length: length,
            size: size,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DriftRootTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$DriftRootTable,
    i1.DriftRootData,
    i1.$$DriftRootTableFilterComposer,
    i1.$$DriftRootTableOrderingComposer,
    i1.$$DriftRootTableAnnotationComposer,
    $$DriftRootTableCreateCompanionBuilder,
    $$DriftRootTableUpdateCompanionBuilder,
    (
      i1.DriftRootData,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$DriftRootTable,
          i1.DriftRootData>
    ),
    i1.DriftRootData,
    i0.PrefetchHooks Function()>;

class $DriftRootTable extends i2.DriftRoot
    with i0.TableInfo<$DriftRootTable, i1.DriftRootData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftRootTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      check: () => id.equals(0),
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const i3.Constant(0));
  static const i0.VerificationMeta _lengthMeta =
      const i0.VerificationMeta('length');
  @override
  late final i0.GeneratedColumn<int> length = i0.GeneratedColumn<int>(
      'length', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const i3.Constant(0));
  static const i0.VerificationMeta _sizeMeta =
      const i0.VerificationMeta('size');
  @override
  late final i0.GeneratedColumn<int> size = i0.GeneratedColumn<int>(
      'size', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const i3.Constant(0));
  @override
  List<i0.GeneratedColumn> get $columns => [id, length, size];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_root';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.DriftRootData> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('length')) {
      context.handle(_lengthMeta,
          length.isAcceptableOrUnknown(data['length']!, _lengthMeta));
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.DriftRootData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DriftRootData(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      length: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}length'])!,
      size: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}size'])!,
    );
  }

  @override
  $DriftRootTable createAlias(String alias) {
    return $DriftRootTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class DriftRootData extends i0.DataClass
    implements i0.Insertable<i1.DriftRootData> {
  final int id;
  final int length;
  final int size;
  const DriftRootData(
      {required this.id, required this.length, required this.size});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['length'] = i0.Variable<int>(length);
    map['size'] = i0.Variable<int>(size);
    return map;
  }

  i1.DriftRootCompanion toCompanion(bool nullToAbsent) {
    return i1.DriftRootCompanion(
      id: i0.Value(id),
      length: i0.Value(length),
      size: i0.Value(size),
    );
  }

  factory DriftRootData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DriftRootData(
      id: serializer.fromJson<int>(json['id']),
      length: serializer.fromJson<int>(json['length']),
      size: serializer.fromJson<int>(json['size']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'length': serializer.toJson<int>(length),
      'size': serializer.toJson<int>(size),
    };
  }

  i1.DriftRootData copyWith({int? id, int? length, int? size}) =>
      i1.DriftRootData(
        id: id ?? this.id,
        length: length ?? this.length,
        size: size ?? this.size,
      );
  DriftRootData copyWithCompanion(i1.DriftRootCompanion data) {
    return DriftRootData(
      id: data.id.present ? data.id.value : this.id,
      length: data.length.present ? data.length.value : this.length,
      size: data.size.present ? data.size.value : this.size,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftRootData(')
          ..write('id: $id, ')
          ..write('length: $length, ')
          ..write('size: $size')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, length, size);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DriftRootData &&
          other.id == this.id &&
          other.length == this.length &&
          other.size == this.size);
}

class DriftRootCompanion extends i0.UpdateCompanion<i1.DriftRootData> {
  final i0.Value<int> id;
  final i0.Value<int> length;
  final i0.Value<int> size;
  const DriftRootCompanion({
    this.id = const i0.Value.absent(),
    this.length = const i0.Value.absent(),
    this.size = const i0.Value.absent(),
  });
  DriftRootCompanion.insert({
    this.id = const i0.Value.absent(),
    this.length = const i0.Value.absent(),
    this.size = const i0.Value.absent(),
  });
  static i0.Insertable<i1.DriftRootData> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? length,
    i0.Expression<int>? size,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (length != null) 'length': length,
      if (size != null) 'size': size,
    });
  }

  i1.DriftRootCompanion copyWith(
      {i0.Value<int>? id, i0.Value<int>? length, i0.Value<int>? size}) {
    return i1.DriftRootCompanion(
      id: id ?? this.id,
      length: length ?? this.length,
      size: size ?? this.size,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (length.present) {
      map['length'] = i0.Variable<int>(length.value);
    }
    if (size.present) {
      map['size'] = i0.Variable<int>(size.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftRootCompanion(')
          ..write('id: $id, ')
          ..write('length: $length, ')
          ..write('size: $size')
          ..write(')'))
        .toString();
  }
}
