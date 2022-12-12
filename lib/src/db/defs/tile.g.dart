// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetDbTileCollection on Isar {
  IsarCollection<DbTile> get tiles => this.collection();
}

const DbTileSchema = CollectionSchema(
  name: r'DbTile',
  id: -5030120948284417748,
  properties: {
    r'bytes': PropertySchema(
      id: 0,
      name: r'bytes',
      type: IsarType.byteList,
    ),
    r'created': PropertySchema(
      id: 1,
      name: r'created',
      type: IsarType.dateTime,
    ),
    r'length': PropertySchema(
      id: 2,
      name: r'length',
      type: IsarType.float,
    ),
    r'x': PropertySchema(
      id: 3,
      name: r'x',
      type: IsarType.int,
    ),
    r'y': PropertySchema(
      id: 4,
      name: r'y',
      type: IsarType.int,
    ),
    r'z': PropertySchema(
      id: 5,
      name: r'z',
      type: IsarType.int,
    )
  },
  estimateSize: _dbTileEstimateSize,
  serialize: _dbTileSerialize,
  deserialize: _dbTileDeserialize,
  deserializeProp: _dbTileDeserializeProp,
  idName: r'id',
  indexes: {
    r'created': IndexSchema(
      id: 9089682803336859617,
      name: r'created',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'created',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dbTileGetId,
  getLinks: _dbTileGetLinks,
  attach: _dbTileAttach,
  version: '3.0.5',
);

int _dbTileEstimateSize(
  DbTile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bytes.length;
  return bytesCount;
}

void _dbTileSerialize(
  DbTile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByteList(offsets[0], object.bytes);
  writer.writeDateTime(offsets[1], object.created);
  writer.writeFloat(offsets[2], object.length);
  writer.writeInt(offsets[3], object.x);
  writer.writeInt(offsets[4], object.y);
  writer.writeInt(offsets[5], object.z);
}

DbTile _dbTileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbTile(
    bytes: reader.readByteList(offsets[0]) ?? [],
    x: reader.readInt(offsets[3]),
    y: reader.readInt(offsets[4]),
    z: reader.readInt(offsets[5]),
  );
  return object;
}

P _dbTileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readByteList(offset) ?? []) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readFloat(offset)) as P;
    case 3:
      return (reader.readInt(offset)) as P;
    case 4:
      return (reader.readInt(offset)) as P;
    case 5:
      return (reader.readInt(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbTileGetId(DbTile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbTileGetLinks(DbTile object) {
  return [];
}

void _dbTileAttach(IsarCollection<dynamic> col, Id id, DbTile object) {}

extension DbTileQueryWhereSort on QueryBuilder<DbTile, DbTile, QWhere> {
  QueryBuilder<DbTile, DbTile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhere> anyCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'created'),
      );
    });
  }
}

extension DbTileQueryWhere on QueryBuilder<DbTile, DbTile, QWhereClause> {
  QueryBuilder<DbTile, DbTile, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> idBetween(
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

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> createdEqualTo(
      DateTime created) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'created',
        value: [created],
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> createdNotEqualTo(
      DateTime created) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'created',
              lower: [],
              upper: [created],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'created',
              lower: [created],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'created',
              lower: [created],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'created',
              lower: [],
              upper: [created],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> createdGreaterThan(
    DateTime created, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'created',
        lower: [created],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> createdLessThan(
    DateTime created, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'created',
        lower: [],
        upper: [created],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterWhereClause> createdBetween(
    DateTime lowerCreated,
    DateTime upperCreated, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'created',
        lower: [lowerCreated],
        includeLower: includeLower,
        upper: [upperCreated],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbTileQueryFilter on QueryBuilder<DbTile, DbTile, QFilterCondition> {
  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bytes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bytes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bytes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> bytesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> createdEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'created',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> createdGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'created',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> createdLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'created',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> createdBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'created',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> lengthEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> lengthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> lengthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> lengthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'length',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> xEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'x',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> xGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'x',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> xLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'x',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> xBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'x',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> yEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'y',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> yGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'y',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> yLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'y',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> yBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'y',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> zEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'z',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> zGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'z',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> zLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'z',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterFilterCondition> zBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'z',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbTileQueryObject on QueryBuilder<DbTile, DbTile, QFilterCondition> {}

extension DbTileQueryLinks on QueryBuilder<DbTile, DbTile, QFilterCondition> {}

extension DbTileQuerySortBy on QueryBuilder<DbTile, DbTile, QSortBy> {
  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> sortByZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.desc);
    });
  }
}

extension DbTileQuerySortThenBy on QueryBuilder<DbTile, DbTile, QSortThenBy> {
  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.desc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.asc);
    });
  }

  QueryBuilder<DbTile, DbTile, QAfterSortBy> thenByZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.desc);
    });
  }
}

extension DbTileQueryWhereDistinct on QueryBuilder<DbTile, DbTile, QDistinct> {
  QueryBuilder<DbTile, DbTile, QDistinct> distinctByBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bytes');
    });
  }

  QueryBuilder<DbTile, DbTile, QDistinct> distinctByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created');
    });
  }

  QueryBuilder<DbTile, DbTile, QDistinct> distinctByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'length');
    });
  }

  QueryBuilder<DbTile, DbTile, QDistinct> distinctByX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'x');
    });
  }

  QueryBuilder<DbTile, DbTile, QDistinct> distinctByY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'y');
    });
  }

  QueryBuilder<DbTile, DbTile, QDistinct> distinctByZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'z');
    });
  }
}

extension DbTileQueryProperty on QueryBuilder<DbTile, DbTile, QQueryProperty> {
  QueryBuilder<DbTile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbTile, List<int>, QQueryOperations> bytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bytes');
    });
  }

  QueryBuilder<DbTile, DateTime, QQueryOperations> createdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created');
    });
  }

  QueryBuilder<DbTile, double, QQueryOperations> lengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'length');
    });
  }

  QueryBuilder<DbTile, int, QQueryOperations> xProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'x');
    });
  }

  QueryBuilder<DbTile, int, QQueryOperations> yProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'y');
    });
  }

  QueryBuilder<DbTile, int, QQueryOperations> zProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'z');
    });
  }
}
