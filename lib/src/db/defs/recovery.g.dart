// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbRecoverableRegionCollection on Isar {
  IsarCollection<DbRecoverableRegion> get recovery => this.collection();
}

const DbRecoverableRegionSchema = CollectionSchema(
  name: r'DbRecoverableRegion',
  id: -8117814053675000476,
  properties: {
    r'centerLat': PropertySchema(
      id: 0,
      name: r'centerLat',
      type: IsarType.float,
    ),
    r'centerLng': PropertySchema(
      id: 1,
      name: r'centerLng',
      type: IsarType.float,
    ),
    r'circleRadius': PropertySchema(
      id: 2,
      name: r'circleRadius',
      type: IsarType.float,
    ),
    r'end': PropertySchema(
      id: 3,
      name: r'end',
      type: IsarType.int,
    ),
    r'linePointsLat': PropertySchema(
      id: 4,
      name: r'linePointsLat',
      type: IsarType.floatList,
    ),
    r'linePointsLng': PropertySchema(
      id: 5,
      name: r'linePointsLng',
      type: IsarType.floatList,
    ),
    r'lineRadius': PropertySchema(
      id: 6,
      name: r'lineRadius',
      type: IsarType.float,
    ),
    r'maxZoom': PropertySchema(
      id: 7,
      name: r'maxZoom',
      type: IsarType.byte,
    ),
    r'minZoom': PropertySchema(
      id: 8,
      name: r'minZoom',
      type: IsarType.byte,
    ),
    r'nwLat': PropertySchema(
      id: 9,
      name: r'nwLat',
      type: IsarType.float,
    ),
    r'nwLng': PropertySchema(
      id: 10,
      name: r'nwLng',
      type: IsarType.float,
    ),
    r'seLat': PropertySchema(
      id: 11,
      name: r'seLat',
      type: IsarType.float,
    ),
    r'seLng': PropertySchema(
      id: 12,
      name: r'seLng',
      type: IsarType.float,
    ),
    r'start': PropertySchema(
      id: 13,
      name: r'start',
      type: IsarType.int,
    ),
    r'storeName': PropertySchema(
      id: 14,
      name: r'storeName',
      type: IsarType.string,
    ),
    r'time': PropertySchema(
      id: 15,
      name: r'time',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 16,
      name: r'type',
      type: IsarType.byte,
      enumMap: _DbRecoverableRegiontypeEnumValueMap,
    )
  },
  estimateSize: _dbRecoverableRegionEstimateSize,
  serialize: _dbRecoverableRegionSerialize,
  deserialize: _dbRecoverableRegionDeserialize,
  deserializeProp: _dbRecoverableRegionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbRecoverableRegionGetId,
  getLinks: _dbRecoverableRegionGetLinks,
  attach: _dbRecoverableRegionAttach,
  version: '3.1.0+1',
);

int _dbRecoverableRegionEstimateSize(
  DbRecoverableRegion object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.linePointsLat;
    if (value != null) {
      bytesCount += 3 + value.length * 4;
    }
  }
  {
    final value = object.linePointsLng;
    if (value != null) {
      bytesCount += 3 + value.length * 4;
    }
  }
  bytesCount += 3 + object.storeName.length * 3;
  return bytesCount;
}

void _dbRecoverableRegionSerialize(
  DbRecoverableRegion object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeFloat(offsets[0], object.centerLat);
  writer.writeFloat(offsets[1], object.centerLng);
  writer.writeFloat(offsets[2], object.circleRadius);
  writer.writeInt(offsets[3], object.end);
  writer.writeFloatList(offsets[4], object.linePointsLat);
  writer.writeFloatList(offsets[5], object.linePointsLng);
  writer.writeFloat(offsets[6], object.lineRadius);
  writer.writeByte(offsets[7], object.maxZoom);
  writer.writeByte(offsets[8], object.minZoom);
  writer.writeFloat(offsets[9], object.nwLat);
  writer.writeFloat(offsets[10], object.nwLng);
  writer.writeFloat(offsets[11], object.seLat);
  writer.writeFloat(offsets[12], object.seLng);
  writer.writeInt(offsets[13], object.start);
  writer.writeString(offsets[14], object.storeName);
  writer.writeDateTime(offsets[15], object.time);
  writer.writeByte(offsets[16], object.type.index);
}

DbRecoverableRegion _dbRecoverableRegionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbRecoverableRegion(
    centerLat: reader.readFloatOrNull(offsets[0]),
    centerLng: reader.readFloatOrNull(offsets[1]),
    circleRadius: reader.readFloatOrNull(offsets[2]),
    end: reader.readIntOrNull(offsets[3]),
    id: id,
    linePointsLat: reader.readFloatList(offsets[4]),
    linePointsLng: reader.readFloatList(offsets[5]),
    lineRadius: reader.readFloatOrNull(offsets[6]),
    maxZoom: reader.readByte(offsets[7]),
    minZoom: reader.readByte(offsets[8]),
    nwLat: reader.readFloatOrNull(offsets[9]),
    nwLng: reader.readFloatOrNull(offsets[10]),
    seLat: reader.readFloatOrNull(offsets[11]),
    seLng: reader.readFloatOrNull(offsets[12]),
    start: reader.readInt(offsets[13]),
    storeName: reader.readString(offsets[14]),
    time: reader.readDateTime(offsets[15]),
    type: _DbRecoverableRegiontypeValueEnumMap[
            reader.readByteOrNull(offsets[16])] ??
        RegionType.rectangle,
  );
  return object;
}

P _dbRecoverableRegionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readFloatOrNull(offset)) as P;
    case 1:
      return (reader.readFloatOrNull(offset)) as P;
    case 2:
      return (reader.readFloatOrNull(offset)) as P;
    case 3:
      return (reader.readIntOrNull(offset)) as P;
    case 4:
      return (reader.readFloatList(offset)) as P;
    case 5:
      return (reader.readFloatList(offset)) as P;
    case 6:
      return (reader.readFloatOrNull(offset)) as P;
    case 7:
      return (reader.readByte(offset)) as P;
    case 8:
      return (reader.readByte(offset)) as P;
    case 9:
      return (reader.readFloatOrNull(offset)) as P;
    case 10:
      return (reader.readFloatOrNull(offset)) as P;
    case 11:
      return (reader.readFloatOrNull(offset)) as P;
    case 12:
      return (reader.readFloatOrNull(offset)) as P;
    case 13:
      return (reader.readInt(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (_DbRecoverableRegiontypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          RegionType.rectangle) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DbRecoverableRegiontypeEnumValueMap = {
  'rectangle': 0,
  'circle': 1,
  'line': 2,
};
const _DbRecoverableRegiontypeValueEnumMap = {
  0: RegionType.rectangle,
  1: RegionType.circle,
  2: RegionType.line,
};

Id _dbRecoverableRegionGetId(DbRecoverableRegion object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbRecoverableRegionGetLinks(
    DbRecoverableRegion object) {
  return [];
}

void _dbRecoverableRegionAttach(
    IsarCollection<dynamic> col, Id id, DbRecoverableRegion object) {}

extension DbRecoverableRegionQueryWhereSort
    on QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QWhere> {
  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbRecoverableRegionQueryWhere
    on QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QWhereClause> {
  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbRecoverableRegionQueryFilter on QueryBuilder<DbRecoverableRegion,
    DbRecoverableRegion, QFilterCondition> {
  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'centerLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'centerLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'centerLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'centerLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'centerLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'centerLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLngIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'centerLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLngIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'centerLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLngEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'centerLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLngGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'centerLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLngLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'centerLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      centerLngBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'centerLng',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      circleRadiusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'circleRadius',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      circleRadiusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'circleRadius',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      circleRadiusEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'circleRadius',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      circleRadiusGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'circleRadius',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      circleRadiusLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'circleRadius',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      circleRadiusBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'circleRadius',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      endIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'end',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      endIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'end',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      endEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      endGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      endLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      endBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'linePointsLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'linePointsLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linePointsLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linePointsLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linePointsLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linePointsLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLat',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLat',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLat',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLat',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLat',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLatLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLat',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'linePointsLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'linePointsLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linePointsLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linePointsLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linePointsLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linePointsLng',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLng',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLng',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLng',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLng',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLng',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      linePointsLngLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linePointsLng',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      lineRadiusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lineRadius',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      lineRadiusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lineRadius',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      lineRadiusEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lineRadius',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      lineRadiusGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lineRadius',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      lineRadiusLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lineRadius',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      lineRadiusBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lineRadius',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      maxZoomEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      maxZoomGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      maxZoomLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      maxZoomBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxZoom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      minZoomEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      minZoomGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      minZoomLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      minZoomBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minZoom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nwLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nwLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nwLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nwLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nwLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nwLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLngIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nwLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLngIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nwLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLngEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nwLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLngGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nwLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLngLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nwLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      nwLngBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nwLng',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seLat',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLngIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLngIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seLng',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLngEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLngGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLngLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seLng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      seLngBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seLng',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      startEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      startGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      startLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      startBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'start',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'storeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'storeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storeName',
        value: '',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      storeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'storeName',
        value: '',
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      timeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      timeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      timeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      timeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'time',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      typeEqualTo(RegionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      typeGreaterThan(
    RegionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      typeLessThan(
    RegionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterFilterCondition>
      typeBetween(
    RegionType lower,
    RegionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbRecoverableRegionQueryObject on QueryBuilder<DbRecoverableRegion,
    DbRecoverableRegion, QFilterCondition> {}

extension DbRecoverableRegionQueryLinks on QueryBuilder<DbRecoverableRegion,
    DbRecoverableRegion, QFilterCondition> {}

extension DbRecoverableRegionQuerySortBy
    on QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QSortBy> {
  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByCenterLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLat', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByCenterLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLat', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByCenterLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLng', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByCenterLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLng', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByCircleRadius() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleRadius', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByCircleRadiusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleRadius', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByLineRadius() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineRadius', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByLineRadiusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineRadius', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByMaxZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByMaxZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByMinZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByMinZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByNwLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLat', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByNwLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLat', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByNwLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLng', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByNwLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLng', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortBySeLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLat', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortBySeLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLat', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortBySeLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLng', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortBySeLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLng', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByStoreName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByStoreNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension DbRecoverableRegionQuerySortThenBy
    on QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QSortThenBy> {
  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByCenterLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLat', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByCenterLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLat', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByCenterLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLng', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByCenterLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'centerLng', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByCircleRadius() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleRadius', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByCircleRadiusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleRadius', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByLineRadius() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineRadius', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByLineRadiusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lineRadius', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByMaxZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByMaxZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByMinZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByMinZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByNwLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLat', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByNwLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLat', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByNwLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLng', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByNwLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nwLng', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenBySeLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLat', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenBySeLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLat', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenBySeLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLng', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenBySeLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seLng', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByStoreName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByStoreNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension DbRecoverableRegionQueryWhereDistinct
    on QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct> {
  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByCenterLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'centerLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByCenterLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'centerLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByCircleRadius() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'circleRadius');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'end');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByLinePointsLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linePointsLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByLinePointsLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linePointsLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByLineRadius() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lineRadius');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByMaxZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxZoom');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByMinZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minZoom');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByNwLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nwLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByNwLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nwLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctBySeLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctBySeLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'start');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByStoreName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'time');
    });
  }

  QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QDistinct>
      distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension DbRecoverableRegionQueryProperty
    on QueryBuilder<DbRecoverableRegion, DbRecoverableRegion, QQueryProperty> {
  QueryBuilder<DbRecoverableRegion, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations>
      centerLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'centerLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations>
      centerLngProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'centerLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations>
      circleRadiusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'circleRadius');
    });
  }

  QueryBuilder<DbRecoverableRegion, int?, QQueryOperations> endProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'end');
    });
  }

  QueryBuilder<DbRecoverableRegion, List<double>?, QQueryOperations>
      linePointsLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linePointsLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, List<double>?, QQueryOperations>
      linePointsLngProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linePointsLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations>
      lineRadiusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lineRadius');
    });
  }

  QueryBuilder<DbRecoverableRegion, int, QQueryOperations> maxZoomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxZoom');
    });
  }

  QueryBuilder<DbRecoverableRegion, int, QQueryOperations> minZoomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minZoom');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations> nwLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nwLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations> nwLngProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nwLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations> seLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seLat');
    });
  }

  QueryBuilder<DbRecoverableRegion, double?, QQueryOperations> seLngProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seLng');
    });
  }

  QueryBuilder<DbRecoverableRegion, int, QQueryOperations> startProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'start');
    });
  }

  QueryBuilder<DbRecoverableRegion, String, QQueryOperations>
      storeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storeName');
    });
  }

  QueryBuilder<DbRecoverableRegion, DateTime, QQueryOperations> timeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'time');
    });
  }

  QueryBuilder<DbRecoverableRegion, RegionType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
