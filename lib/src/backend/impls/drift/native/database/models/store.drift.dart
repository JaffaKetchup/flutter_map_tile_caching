// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store.drift.dart'
    as i1;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/store.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;

typedef $$DriftStoreTableCreateCompanionBuilder = i1.DriftStoreCompanion
    Function({
  required String name,
  i0.Value<int?> maxLength,
  i0.Value<int> length,
  i0.Value<int> size,
  i0.Value<int> hits,
  i0.Value<int> misses,
  i0.Value<String> metadataJson,
});
typedef $$DriftStoreTableUpdateCompanionBuilder = i1.DriftStoreCompanion
    Function({
  i0.Value<String> name,
  i0.Value<int?> maxLength,
  i0.Value<int> length,
  i0.Value<int> size,
  i0.Value<int> hits,
  i0.Value<int> misses,
  i0.Value<String> metadataJson,
});

class $$DriftStoreTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftStoreTable> {
  $$DriftStoreTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get maxLength => $composableBuilder(
      column: $table.maxLength, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get length => $composableBuilder(
      column: $table.length, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get hits => $composableBuilder(
      column: $table.hits, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<int> get misses => $composableBuilder(
      column: $table.misses, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => i0.ColumnFilters(column));
}

class $$DriftStoreTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftStoreTable> {
  $$DriftStoreTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get maxLength => $composableBuilder(
      column: $table.maxLength,
      builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get length => $composableBuilder(
      column: $table.length, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get hits => $composableBuilder(
      column: $table.hits, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<int> get misses => $composableBuilder(
      column: $table.misses, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => i0.ColumnOrderings(column));
}

class $$DriftStoreTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftStoreTable> {
  $$DriftStoreTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<int> get maxLength =>
      $composableBuilder(column: $table.maxLength, builder: (column) => column);

  i0.GeneratedColumn<int> get length =>
      $composableBuilder(column: $table.length, builder: (column) => column);

  i0.GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  i0.GeneratedColumn<int> get hits =>
      $composableBuilder(column: $table.hits, builder: (column) => column);

  i0.GeneratedColumn<int> get misses =>
      $composableBuilder(column: $table.misses, builder: (column) => column);

  i0.GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);
}

class $$DriftStoreTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$DriftStoreTable,
    i1.DriftStoreData,
    i1.$$DriftStoreTableFilterComposer,
    i1.$$DriftStoreTableOrderingComposer,
    i1.$$DriftStoreTableAnnotationComposer,
    $$DriftStoreTableCreateCompanionBuilder,
    $$DriftStoreTableUpdateCompanionBuilder,
    (
      i1.DriftStoreData,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$DriftStoreTable,
          i1.DriftStoreData>
    ),
    i1.DriftStoreData,
    i0.PrefetchHooks Function()> {
  $$DriftStoreTableTableManager(
      i0.GeneratedDatabase db, i1.$DriftStoreTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$DriftStoreTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DriftStoreTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$DriftStoreTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<String> name = const i0.Value.absent(),
            i0.Value<int?> maxLength = const i0.Value.absent(),
            i0.Value<int> length = const i0.Value.absent(),
            i0.Value<int> size = const i0.Value.absent(),
            i0.Value<int> hits = const i0.Value.absent(),
            i0.Value<int> misses = const i0.Value.absent(),
            i0.Value<String> metadataJson = const i0.Value.absent(),
          }) =>
              i1.DriftStoreCompanion(
            name: name,
            maxLength: maxLength,
            length: length,
            size: size,
            hits: hits,
            misses: misses,
            metadataJson: metadataJson,
          ),
          createCompanionCallback: ({
            required String name,
            i0.Value<int?> maxLength = const i0.Value.absent(),
            i0.Value<int> length = const i0.Value.absent(),
            i0.Value<int> size = const i0.Value.absent(),
            i0.Value<int> hits = const i0.Value.absent(),
            i0.Value<int> misses = const i0.Value.absent(),
            i0.Value<String> metadataJson = const i0.Value.absent(),
          }) =>
              i1.DriftStoreCompanion.insert(
            name: name,
            maxLength: maxLength,
            length: length,
            size: size,
            hits: hits,
            misses: misses,
            metadataJson: metadataJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DriftStoreTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$DriftStoreTable,
    i1.DriftStoreData,
    i1.$$DriftStoreTableFilterComposer,
    i1.$$DriftStoreTableOrderingComposer,
    i1.$$DriftStoreTableAnnotationComposer,
    $$DriftStoreTableCreateCompanionBuilder,
    $$DriftStoreTableUpdateCompanionBuilder,
    (
      i1.DriftStoreData,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$DriftStoreTable,
          i1.DriftStoreData>
    ),
    i1.DriftStoreData,
    i0.PrefetchHooks Function()>;

class $DriftStoreTable extends i2.DriftStore
    with i0.TableInfo<$DriftStoreTable, i1.DriftStoreData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftStoreTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _nameMeta =
      const i0.VerificationMeta('name');
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
      'name', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _maxLengthMeta =
      const i0.VerificationMeta('maxLength');
  @override
  late final i0.GeneratedColumn<int> maxLength = i0.GeneratedColumn<int>(
      'max_length', aliasedName, true,
      type: i0.DriftSqlType.int, requiredDuringInsert: false);
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
  static const i0.VerificationMeta _hitsMeta =
      const i0.VerificationMeta('hits');
  @override
  late final i0.GeneratedColumn<int> hits = i0.GeneratedColumn<int>(
      'hits', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const i3.Constant(0));
  static const i0.VerificationMeta _missesMeta =
      const i0.VerificationMeta('misses');
  @override
  late final i0.GeneratedColumn<int> misses = i0.GeneratedColumn<int>(
      'misses', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const i3.Constant(0));
  static const i0.VerificationMeta _metadataJsonMeta =
      const i0.VerificationMeta('metadataJson');
  @override
  late final i0.GeneratedColumn<String> metadataJson =
      i0.GeneratedColumn<String>('metadata_json', aliasedName, false,
          type: i0.DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const i3.Constant('{}'));
  @override
  List<i0.GeneratedColumn> get $columns =>
      [name, maxLength, length, size, hits, misses, metadataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_store';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.DriftStoreData> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('max_length')) {
      context.handle(_maxLengthMeta,
          maxLength.isAcceptableOrUnknown(data['max_length']!, _maxLengthMeta));
    }
    if (data.containsKey('length')) {
      context.handle(_lengthMeta,
          length.isAcceptableOrUnknown(data['length']!, _lengthMeta));
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    }
    if (data.containsKey('hits')) {
      context.handle(
          _hitsMeta, hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta));
    }
    if (data.containsKey('misses')) {
      context.handle(_missesMeta,
          misses.isAcceptableOrUnknown(data['misses']!, _missesMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {name};
  @override
  i1.DriftStoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DriftStoreData(
      name: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}name'])!,
      maxLength: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}max_length']),
      length: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}length'])!,
      size: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}size'])!,
      hits: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}hits'])!,
      misses: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}misses'])!,
      metadataJson: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.string, data['${effectivePrefix}metadata_json'])!,
    );
  }

  @override
  $DriftStoreTable createAlias(String alias) {
    return $DriftStoreTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
}

class DriftStoreData extends i0.DataClass
    implements i0.Insertable<i1.DriftStoreData> {
  final String name;
  final int? maxLength;
  final int length;
  final int size;
  final int hits;
  final int misses;
  final String metadataJson;
  const DriftStoreData(
      {required this.name,
      this.maxLength,
      required this.length,
      required this.size,
      required this.hits,
      required this.misses,
      required this.metadataJson});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || maxLength != null) {
      map['max_length'] = i0.Variable<int>(maxLength);
    }
    map['length'] = i0.Variable<int>(length);
    map['size'] = i0.Variable<int>(size);
    map['hits'] = i0.Variable<int>(hits);
    map['misses'] = i0.Variable<int>(misses);
    map['metadata_json'] = i0.Variable<String>(metadataJson);
    return map;
  }

  i1.DriftStoreCompanion toCompanion(bool nullToAbsent) {
    return i1.DriftStoreCompanion(
      name: i0.Value(name),
      maxLength: maxLength == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(maxLength),
      length: i0.Value(length),
      size: i0.Value(size),
      hits: i0.Value(hits),
      misses: i0.Value(misses),
      metadataJson: i0.Value(metadataJson),
    );
  }

  factory DriftStoreData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DriftStoreData(
      name: serializer.fromJson<String>(json['name']),
      maxLength: serializer.fromJson<int?>(json['maxLength']),
      length: serializer.fromJson<int>(json['length']),
      size: serializer.fromJson<int>(json['size']),
      hits: serializer.fromJson<int>(json['hits']),
      misses: serializer.fromJson<int>(json['misses']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'maxLength': serializer.toJson<int?>(maxLength),
      'length': serializer.toJson<int>(length),
      'size': serializer.toJson<int>(size),
      'hits': serializer.toJson<int>(hits),
      'misses': serializer.toJson<int>(misses),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  i1.DriftStoreData copyWith(
          {String? name,
          i0.Value<int?> maxLength = const i0.Value.absent(),
          int? length,
          int? size,
          int? hits,
          int? misses,
          String? metadataJson}) =>
      i1.DriftStoreData(
        name: name ?? this.name,
        maxLength: maxLength.present ? maxLength.value : this.maxLength,
        length: length ?? this.length,
        size: size ?? this.size,
        hits: hits ?? this.hits,
        misses: misses ?? this.misses,
        metadataJson: metadataJson ?? this.metadataJson,
      );
  DriftStoreData copyWithCompanion(i1.DriftStoreCompanion data) {
    return DriftStoreData(
      name: data.name.present ? data.name.value : this.name,
      maxLength: data.maxLength.present ? data.maxLength.value : this.maxLength,
      length: data.length.present ? data.length.value : this.length,
      size: data.size.present ? data.size.value : this.size,
      hits: data.hits.present ? data.hits.value : this.hits,
      misses: data.misses.present ? data.misses.value : this.misses,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftStoreData(')
          ..write('name: $name, ')
          ..write('maxLength: $maxLength, ')
          ..write('length: $length, ')
          ..write('size: $size, ')
          ..write('hits: $hits, ')
          ..write('misses: $misses, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(name, maxLength, length, size, hits, misses, metadataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DriftStoreData &&
          other.name == this.name &&
          other.maxLength == this.maxLength &&
          other.length == this.length &&
          other.size == this.size &&
          other.hits == this.hits &&
          other.misses == this.misses &&
          other.metadataJson == this.metadataJson);
}

class DriftStoreCompanion extends i0.UpdateCompanion<i1.DriftStoreData> {
  final i0.Value<String> name;
  final i0.Value<int?> maxLength;
  final i0.Value<int> length;
  final i0.Value<int> size;
  final i0.Value<int> hits;
  final i0.Value<int> misses;
  final i0.Value<String> metadataJson;
  const DriftStoreCompanion({
    this.name = const i0.Value.absent(),
    this.maxLength = const i0.Value.absent(),
    this.length = const i0.Value.absent(),
    this.size = const i0.Value.absent(),
    this.hits = const i0.Value.absent(),
    this.misses = const i0.Value.absent(),
    this.metadataJson = const i0.Value.absent(),
  });
  DriftStoreCompanion.insert({
    required String name,
    this.maxLength = const i0.Value.absent(),
    this.length = const i0.Value.absent(),
    this.size = const i0.Value.absent(),
    this.hits = const i0.Value.absent(),
    this.misses = const i0.Value.absent(),
    this.metadataJson = const i0.Value.absent(),
  }) : name = i0.Value(name);
  static i0.Insertable<i1.DriftStoreData> custom({
    i0.Expression<String>? name,
    i0.Expression<int>? maxLength,
    i0.Expression<int>? length,
    i0.Expression<int>? size,
    i0.Expression<int>? hits,
    i0.Expression<int>? misses,
    i0.Expression<String>? metadataJson,
  }) {
    return i0.RawValuesInsertable({
      if (name != null) 'name': name,
      if (maxLength != null) 'max_length': maxLength,
      if (length != null) 'length': length,
      if (size != null) 'size': size,
      if (hits != null) 'hits': hits,
      if (misses != null) 'misses': misses,
      if (metadataJson != null) 'metadata_json': metadataJson,
    });
  }

  i1.DriftStoreCompanion copyWith(
      {i0.Value<String>? name,
      i0.Value<int?>? maxLength,
      i0.Value<int>? length,
      i0.Value<int>? size,
      i0.Value<int>? hits,
      i0.Value<int>? misses,
      i0.Value<String>? metadataJson}) {
    return i1.DriftStoreCompanion(
      name: name ?? this.name,
      maxLength: maxLength ?? this.maxLength,
      length: length ?? this.length,
      size: size ?? this.size,
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (maxLength.present) {
      map['max_length'] = i0.Variable<int>(maxLength.value);
    }
    if (length.present) {
      map['length'] = i0.Variable<int>(length.value);
    }
    if (size.present) {
      map['size'] = i0.Variable<int>(size.value);
    }
    if (hits.present) {
      map['hits'] = i0.Variable<int>(hits.value);
    }
    if (misses.present) {
      map['misses'] = i0.Variable<int>(misses.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = i0.Variable<String>(metadataJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftStoreCompanion(')
          ..write('name: $name, ')
          ..write('maxLength: $maxLength, ')
          ..write('length: $length, ')
          ..write('size: $size, ')
          ..write('hits: $hits, ')
          ..write('misses: $misses, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }
}
