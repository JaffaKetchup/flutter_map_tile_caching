// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/tile.drift.dart'
    as i1;
import 'dart:typed_data' as i2;
import 'package:flutter_map_tile_caching/src/backend/impls/drift/native/database/models/tile.dart'
    as i3;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i4;

typedef $$DriftTileTableCreateCompanionBuilder = i1.DriftTileCompanion
    Function({
  required String uid,
  required i2.Uint8List bytes,
  i0.Value<DateTime> lastModified,
  i0.Value<int> rowid,
});
typedef $$DriftTileTableUpdateCompanionBuilder = i1.DriftTileCompanion
    Function({
  i0.Value<String> uid,
  i0.Value<i2.Uint8List> bytes,
  i0.Value<DateTime> lastModified,
  i0.Value<int> rowid,
});

class $$DriftTileTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftTileTable> {
  $$DriftTileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<i2.Uint8List> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => i0.ColumnFilters(column));
}

class $$DriftTileTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftTileTable> {
  $$DriftTileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<i2.Uint8List> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => i0.ColumnOrderings(column));
}

class $$DriftTileTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DriftTileTable> {
  $$DriftTileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  i0.GeneratedColumn<i2.Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);
}

class $$DriftTileTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$DriftTileTable,
    i1.DriftTileData,
    i1.$$DriftTileTableFilterComposer,
    i1.$$DriftTileTableOrderingComposer,
    i1.$$DriftTileTableAnnotationComposer,
    $$DriftTileTableCreateCompanionBuilder,
    $$DriftTileTableUpdateCompanionBuilder,
    (
      i1.DriftTileData,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$DriftTileTable,
          i1.DriftTileData>
    ),
    i1.DriftTileData,
    i0.PrefetchHooks Function()> {
  $$DriftTileTableTableManager(
      i0.GeneratedDatabase db, i1.$DriftTileTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$DriftTileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DriftTileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$DriftTileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<String> uid = const i0.Value.absent(),
            i0.Value<i2.Uint8List> bytes = const i0.Value.absent(),
            i0.Value<DateTime> lastModified = const i0.Value.absent(),
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i1.DriftTileCompanion(
            uid: uid,
            bytes: bytes,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required i2.Uint8List bytes,
            i0.Value<DateTime> lastModified = const i0.Value.absent(),
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i1.DriftTileCompanion.insert(
            uid: uid,
            bytes: bytes,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DriftTileTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$DriftTileTable,
    i1.DriftTileData,
    i1.$$DriftTileTableFilterComposer,
    i1.$$DriftTileTableOrderingComposer,
    i1.$$DriftTileTableAnnotationComposer,
    $$DriftTileTableCreateCompanionBuilder,
    $$DriftTileTableUpdateCompanionBuilder,
    (
      i1.DriftTileData,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$DriftTileTable,
          i1.DriftTileData>
    ),
    i1.DriftTileData,
    i0.PrefetchHooks Function()>;
i0.Index get lastModified => i0.Index('last_modified',
    'CREATE INDEX last_modified ON drift_tile (last_modified)');

class $DriftTileTable extends i3.DriftTile
    with i0.TableInfo<$DriftTileTable, i1.DriftTileData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftTileTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _uidMeta = const i0.VerificationMeta('uid');
  @override
  late final i0.GeneratedColumn<String> uid = i0.GeneratedColumn<String>(
      'uid', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _bytesMeta =
      const i0.VerificationMeta('bytes');
  @override
  late final i0.GeneratedColumn<i2.Uint8List> bytes =
      i0.GeneratedColumn<i2.Uint8List>('bytes', aliasedName, false,
          type: i0.DriftSqlType.blob, requiredDuringInsert: true);
  static const i0.VerificationMeta _lastModifiedMeta =
      const i0.VerificationMeta('lastModified');
  @override
  late final i0.GeneratedColumn<DateTime> lastModified =
      i0.GeneratedColumn<DateTime>('last_modified', aliasedName, false,
          type: i0.DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: i4.currentDateAndTime);
  @override
  List<i0.GeneratedColumn> get $columns => [uid, bytes, lastModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_tile';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.DriftTileData> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {uid};
  @override
  i1.DriftTileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DriftTileData(
      uid: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}uid'])!,
      bytes: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.blob, data['${effectivePrefix}bytes'])!,
      lastModified: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $DriftTileTable createAlias(String alias) {
    return $DriftTileTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class DriftTileData extends i0.DataClass
    implements i0.Insertable<i1.DriftTileData> {
  final String uid;
  final i2.Uint8List bytes;
  final DateTime lastModified;
  const DriftTileData(
      {required this.uid, required this.bytes, required this.lastModified});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['uid'] = i0.Variable<String>(uid);
    map['bytes'] = i0.Variable<i2.Uint8List>(bytes);
    map['last_modified'] = i0.Variable<DateTime>(lastModified);
    return map;
  }

  i1.DriftTileCompanion toCompanion(bool nullToAbsent) {
    return i1.DriftTileCompanion(
      uid: i0.Value(uid),
      bytes: i0.Value(bytes),
      lastModified: i0.Value(lastModified),
    );
  }

  factory DriftTileData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DriftTileData(
      uid: serializer.fromJson<String>(json['uid']),
      bytes: serializer.fromJson<i2.Uint8List>(json['bytes']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'bytes': serializer.toJson<i2.Uint8List>(bytes),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  i1.DriftTileData copyWith(
          {String? uid, i2.Uint8List? bytes, DateTime? lastModified}) =>
      i1.DriftTileData(
        uid: uid ?? this.uid,
        bytes: bytes ?? this.bytes,
        lastModified: lastModified ?? this.lastModified,
      );
  DriftTileData copyWithCompanion(i1.DriftTileCompanion data) {
    return DriftTileData(
      uid: data.uid.present ? data.uid.value : this.uid,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftTileData(')
          ..write('uid: $uid, ')
          ..write('bytes: $bytes, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, i0.$driftBlobEquality.hash(bytes), lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DriftTileData &&
          other.uid == this.uid &&
          i0.$driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.lastModified == this.lastModified);
}

class DriftTileCompanion extends i0.UpdateCompanion<i1.DriftTileData> {
  final i0.Value<String> uid;
  final i0.Value<i2.Uint8List> bytes;
  final i0.Value<DateTime> lastModified;
  final i0.Value<int> rowid;
  const DriftTileCompanion({
    this.uid = const i0.Value.absent(),
    this.bytes = const i0.Value.absent(),
    this.lastModified = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  DriftTileCompanion.insert({
    required String uid,
    required i2.Uint8List bytes,
    this.lastModified = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  })  : uid = i0.Value(uid),
        bytes = i0.Value(bytes);
  static i0.Insertable<i1.DriftTileData> custom({
    i0.Expression<String>? uid,
    i0.Expression<i2.Uint8List>? bytes,
    i0.Expression<DateTime>? lastModified,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (bytes != null) 'bytes': bytes,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.DriftTileCompanion copyWith(
      {i0.Value<String>? uid,
      i0.Value<i2.Uint8List>? bytes,
      i0.Value<DateTime>? lastModified,
      i0.Value<int>? rowid}) {
    return i1.DriftTileCompanion(
      uid: uid ?? this.uid,
      bytes: bytes ?? this.bytes,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (uid.present) {
      map['uid'] = i0.Variable<String>(uid.value);
    }
    if (bytes.present) {
      map['bytes'] = i0.Variable<i2.Uint8List>(bytes.value);
    }
    if (lastModified.present) {
      map['last_modified'] = i0.Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftTileCompanion(')
          ..write('uid: $uid, ')
          ..write('bytes: $bytes, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
