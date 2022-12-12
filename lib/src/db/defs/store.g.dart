// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetDbStoreCollection on Isar {
  IsarCollection<DbStore> get stores => this.collection();
}

const DbStoreSchema = CollectionSchema(
  name: r'DbStore',
  id: -8185066502077300117,
  properties: {
    r'hits': PropertySchema(
      id: 0,
      name: r'hits',
      type: IsarType.long,
    ),
    r'misses': PropertySchema(
      id: 1,
      name: r'misses',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _dbStoreEstimateSize,
  serialize: _dbStoreSerialize,
  deserialize: _dbStoreDeserialize,
  deserializeProp: _dbStoreDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbStoreGetId,
  getLinks: _dbStoreGetLinks,
  attach: _dbStoreAttach,
  version: '3.0.5',
);

int _dbStoreEstimateSize(
  DbStore object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _dbStoreSerialize(
  DbStore object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.hits);
  writer.writeLong(offsets[1], object.misses);
  writer.writeString(offsets[2], object.name);
}

DbStore _dbStoreDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbStore(
    name: reader.readString(offsets[2]),
  );
  object.hits = reader.readLong(offsets[0]);
  object.misses = reader.readLong(offsets[1]);
  return object;
}

P _dbStoreDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbStoreGetId(DbStore object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbStoreGetLinks(DbStore object) {
  return [];
}

void _dbStoreAttach(IsarCollection<dynamic> col, Id id, DbStore object) {}

extension DbStoreQueryWhereSort on QueryBuilder<DbStore, DbStore, QWhere> {
  QueryBuilder<DbStore, DbStore, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbStoreQueryWhere on QueryBuilder<DbStore, DbStore, QWhereClause> {
  QueryBuilder<DbStore, DbStore, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DbStore, DbStore, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterWhereClause> idBetween(
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

extension DbStoreQueryFilter
    on QueryBuilder<DbStore, DbStore, QFilterCondition> {
  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> hitsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hits',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> hitsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hits',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> hitsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hits',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> hitsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hits',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> missesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'misses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> missesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'misses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> missesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'misses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> missesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'misses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension DbStoreQueryObject
    on QueryBuilder<DbStore, DbStore, QFilterCondition> {}

extension DbStoreQueryLinks
    on QueryBuilder<DbStore, DbStore, QFilterCondition> {}

extension DbStoreQuerySortBy on QueryBuilder<DbStore, DbStore, QSortBy> {
  QueryBuilder<DbStore, DbStore, QAfterSortBy> sortByHits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> sortByHitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.desc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> sortByMisses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> sortByMissesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.desc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension DbStoreQuerySortThenBy
    on QueryBuilder<DbStore, DbStore, QSortThenBy> {
  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByHits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByHitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.desc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByMisses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByMissesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.desc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbStore, DbStore, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension DbStoreQueryWhereDistinct
    on QueryBuilder<DbStore, DbStore, QDistinct> {
  QueryBuilder<DbStore, DbStore, QDistinct> distinctByHits() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hits');
    });
  }

  QueryBuilder<DbStore, DbStore, QDistinct> distinctByMisses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'misses');
    });
  }

  QueryBuilder<DbStore, DbStore, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension DbStoreQueryProperty
    on QueryBuilder<DbStore, DbStore, QQueryProperty> {
  QueryBuilder<DbStore, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbStore, int, QQueryOperations> hitsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hits');
    });
  }

  QueryBuilder<DbStore, int, QQueryOperations> missesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'misses');
    });
  }

  QueryBuilder<DbStore, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
