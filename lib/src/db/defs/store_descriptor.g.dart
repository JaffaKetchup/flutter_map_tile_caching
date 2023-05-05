// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_descriptor.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbStoreDescriptorCollection on Isar {
  IsarCollection<DbStoreDescriptor> get storeDescriptor => this.collection();
}

const DbStoreDescriptorSchema = CollectionSchema(
  name: r'DbStoreDescriptor',
  id: 1365152130637522244,
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
  estimateSize: _dbStoreDescriptorEstimateSize,
  serialize: _dbStoreDescriptorSerialize,
  deserialize: _dbStoreDescriptorDeserialize,
  deserializeProp: _dbStoreDescriptorDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbStoreDescriptorGetId,
  getLinks: _dbStoreDescriptorGetLinks,
  attach: _dbStoreDescriptorAttach,
  version: '3.1.0+1',
);

int _dbStoreDescriptorEstimateSize(
  DbStoreDescriptor object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _dbStoreDescriptorSerialize(
  DbStoreDescriptor object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.hits);
  writer.writeLong(offsets[1], object.misses);
  writer.writeString(offsets[2], object.name);
}

DbStoreDescriptor _dbStoreDescriptorDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbStoreDescriptor(
    name: reader.readString(offsets[2]),
  );
  object.hits = reader.readLong(offsets[0]);
  object.misses = reader.readLong(offsets[1]);
  return object;
}

P _dbStoreDescriptorDeserializeProp<P>(
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

Id _dbStoreDescriptorGetId(DbStoreDescriptor object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbStoreDescriptorGetLinks(
    DbStoreDescriptor object) {
  return [];
}

void _dbStoreDescriptorAttach(
    IsarCollection<dynamic> col, Id id, DbStoreDescriptor object) {}

extension DbStoreDescriptorQueryWhereSort
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QWhere> {
  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbStoreDescriptorQueryWhere
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QWhereClause> {
  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterWhereClause>
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterWhereClause>
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

extension DbStoreDescriptorQueryFilter
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QFilterCondition> {
  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      hitsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hits',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      hitsGreaterThan(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      hitsLessThan(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      hitsBetween(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      missesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'misses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      missesGreaterThan(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      missesLessThan(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      missesBetween(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension DbStoreDescriptorQueryObject
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QFilterCondition> {}

extension DbStoreDescriptorQueryLinks
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QFilterCondition> {}

extension DbStoreDescriptorQuerySortBy
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QSortBy> {
  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      sortByHits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      sortByHitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.desc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      sortByMisses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      sortByMissesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.desc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension DbStoreDescriptorQuerySortThenBy
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QSortThenBy> {
  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByHits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByHitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hits', Sort.desc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByMisses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByMissesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'misses', Sort.desc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension DbStoreDescriptorQueryWhereDistinct
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QDistinct> {
  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QDistinct>
      distinctByHits() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hits');
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QDistinct>
      distinctByMisses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'misses');
    });
  }

  QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension DbStoreDescriptorQueryProperty
    on QueryBuilder<DbStoreDescriptor, DbStoreDescriptor, QQueryProperty> {
  QueryBuilder<DbStoreDescriptor, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbStoreDescriptor, int, QQueryOperations> hitsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hits');
    });
  }

  QueryBuilder<DbStoreDescriptor, int, QQueryOperations> missesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'misses');
    });
  }

  QueryBuilder<DbStoreDescriptor, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
