// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again
// with `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types, depend_on_referenced_packages
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'
    as obx_int; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart' as obx;
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

import '../../../../../../src/backend/impls/objectbox/models/src/recovery.dart';
import '../../../../../../src/backend/impls/objectbox/models/src/root.dart';
import '../../../../../../src/backend/impls/objectbox/models/src/store.dart';
import '../../../../../../src/backend/impls/objectbox/models/src/tile.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <obx_int.ModelEntity>[
  obx_int.ModelEntity(
      id: const obx_int.IdUid(1, 5472631385587455945),
      name: 'ObjectBoxRecovery',
      lastPropertyId: const obx_int.IdUid(21, 3590067577930145922),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 3769282896877713230),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 2496811483091029921),
            name: 'refId',
            type: 6,
            flags: 40,
            indexId: const obx_int.IdUid(1, 1036386105099927432)),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 3612512640999075849),
            name: 'storeName',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 1095455913099058361),
            name: 'creationTime',
            type: 10,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 1138350672456876624),
            name: 'minZoom',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 9040433791555820529),
            name: 'maxZoom',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 6819230045021667310),
            name: 'startTile',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 8185724925875119436),
            name: 'endTile',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 7217406424708558740),
            name: 'typeId',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(10, 5971465387225017460),
            name: 'rectNwLat',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(11, 6703340231106164623),
            name: 'rectNwLng',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(12, 741105584939284321),
            name: 'rectSeLat',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(13, 2939837278126242427),
            name: 'rectSeLng',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(14, 2393337671661697697),
            name: 'circleCenterLat',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(15, 8055510540122966413),
            name: 'circleCenterLng',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(16, 9110709438555760246),
            name: 'circleRadius',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(17, 8363656194353400366),
            name: 'lineLats',
            type: 29,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(18, 7008680868853575786),
            name: 'lineLngs',
            type: 29,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(19, 7670007285707179405),
            name: 'lineRadius',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(20, 490933261424375687),
            name: 'customPolygonLats',
            type: 29,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(21, 3590067577930145922),
            name: 'customPolygonLngs',
            type: 29,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(2, 632249766926720928),
      name: 'ObjectBoxStore',
      lastPropertyId: const obx_int.IdUid(7, 7028109958959828879),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 1672655555406818874),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 1060752758288526798),
            name: 'name',
            type: 9,
            flags: 2080,
            indexId: const obx_int.IdUid(2, 5602852847672696920)),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 7375048950056890678),
            name: 'length',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 7781853256122686511),
            name: 'size',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 3183925806131180531),
            name: 'hits',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 6484030110235711573),
            name: 'misses',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 7028109958959828879),
            name: 'metadataJson',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[
        obx_int.ModelBacklink(
            name: 'tiles', srcEntity: 'ObjectBoxTile', srcField: 'stores')
      ]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(3, 8691708694767276679),
      name: 'ObjectBoxTile',
      lastPropertyId: const obx_int.IdUid(4, 1172878417733380836),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 5356545328183635928),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 4115905667778721807),
            name: 'url',
            type: 9,
            flags: 34848,
            indexId: const obx_int.IdUid(3, 4361441212367179043)),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 7508139234299399524),
            name: 'bytes',
            type: 23,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 1172878417733380836),
            name: 'lastModified',
            type: 10,
            flags: 8,
            indexId: const obx_int.IdUid(4, 4857742396480146668))
      ],
      relations: <obx_int.ModelRelation>[
        obx_int.ModelRelation(
            id: const obx_int.IdUid(1, 7496298295217061586),
            name: 'stores',
            targetId: const obx_int.IdUid(2, 632249766926720928))
      ],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(4, 8718814737097934474),
      name: 'ObjectBoxRoot',
      lastPropertyId: const obx_int.IdUid(3, 6574336219794969200),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 3527394784453371799),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 2833017356902860570),
            name: 'length',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 6574336219794969200),
            name: 'size',
            type: 6,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[])
];

/// Shortcut for [obx.Store.new] that passes [getObjectBoxModel] and for Flutter
/// apps by default a [directory] using `defaultStoreDirectory()` from the
/// ObjectBox Flutter library.
///
/// Note: for desktop apps it is recommended to specify a unique [directory].
///
/// See [obx.Store.new] for an explanation of all parameters.
///
/// For Flutter apps, also calls `loadObjectBoxLibraryAndroidCompat()` from
/// the ObjectBox Flutter library to fix loading the native ObjectBox library
/// on Android 6 and older.
Future<obx.Store> openStore(
    {String? directory,
    int? maxDBSizeInKB,
    int? maxDataSizeInKB,
    int? fileMode,
    int? maxReaders,
    bool queriesCaseSensitiveDefault = true,
    String? macosApplicationGroup}) async {
  await loadObjectBoxLibraryAndroidCompat();
  return obx.Store(getObjectBoxModel(),
      directory: directory ?? (await defaultStoreDirectory()).path,
      maxDBSizeInKB: maxDBSizeInKB,
      maxDataSizeInKB: maxDataSizeInKB,
      fileMode: fileMode,
      maxReaders: maxReaders,
      queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
      macosApplicationGroup: macosApplicationGroup);
}

/// Returns the ObjectBox model definition for this project for use with
/// [obx.Store.new].
obx_int.ModelDefinition getObjectBoxModel() {
  final model = obx_int.ModelInfo(
      entities: _entities,
      lastEntityId: const obx_int.IdUid(4, 8718814737097934474),
      lastIndexId: const obx_int.IdUid(4, 4857742396480146668),
      lastRelationId: const obx_int.IdUid(1, 7496298295217061586),
      lastSequenceId: const obx_int.IdUid(0, 0),
      retiredEntityUids: const [],
      retiredIndexUids: const [],
      retiredPropertyUids: const [],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, obx_int.EntityDefinition>{
    ObjectBoxRecovery: obx_int.EntityDefinition<ObjectBoxRecovery>(
        model: _entities[0],
        toOneRelations: (ObjectBoxRecovery object) => [],
        toManyRelations: (ObjectBoxRecovery object) => {},
        getId: (ObjectBoxRecovery object) => object.id,
        setId: (ObjectBoxRecovery object, int id) {
          object.id = id;
        },
        objectToFB: (ObjectBoxRecovery object, fb.Builder fbb) {
          final storeNameOffset = fbb.writeString(object.storeName);
          final lineLatsOffset = object.lineLats == null
              ? null
              : fbb.writeListFloat64(object.lineLats!);
          final lineLngsOffset = object.lineLngs == null
              ? null
              : fbb.writeListFloat64(object.lineLngs!);
          final customPolygonLatsOffset = object.customPolygonLats == null
              ? null
              : fbb.writeListFloat64(object.customPolygonLats!);
          final customPolygonLngsOffset = object.customPolygonLngs == null
              ? null
              : fbb.writeListFloat64(object.customPolygonLngs!);
          fbb.startTable(22);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.refId);
          fbb.addOffset(2, storeNameOffset);
          fbb.addInt64(3, object.creationTime.millisecondsSinceEpoch);
          fbb.addInt64(4, object.minZoom);
          fbb.addInt64(5, object.maxZoom);
          fbb.addInt64(6, object.startTile);
          fbb.addInt64(7, object.endTile);
          fbb.addInt64(8, object.typeId);
          fbb.addFloat64(9, object.rectNwLat);
          fbb.addFloat64(10, object.rectNwLng);
          fbb.addFloat64(11, object.rectSeLat);
          fbb.addFloat64(12, object.rectSeLng);
          fbb.addFloat64(13, object.circleCenterLat);
          fbb.addFloat64(14, object.circleCenterLng);
          fbb.addFloat64(15, object.circleRadius);
          fbb.addOffset(16, lineLatsOffset);
          fbb.addOffset(17, lineLngsOffset);
          fbb.addFloat64(18, object.lineRadius);
          fbb.addOffset(19, customPolygonLatsOffset);
          fbb.addOffset(20, customPolygonLngsOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final refIdParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          final storeNameParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 8, '');
          final creationTimeParam = DateTime.fromMillisecondsSinceEpoch(
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0));
          final typeIdParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 20, 0);
          final minZoomParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0);
          final maxZoomParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 14, 0);
          final startTileParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 16, 0);
          final endTileParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 18, 0);
          final rectNwLatParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 22);
          final rectNwLngParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 24);
          final rectSeLatParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 26);
          final rectSeLngParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 28);
          final circleCenterLatParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 30);
          final circleCenterLngParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 32);
          final circleRadiusParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 34);
          final lineLatsParam =
              const fb.ListReader<double>(fb.Float64Reader(), lazy: false)
                  .vTableGetNullable(buffer, rootOffset, 36);
          final lineLngsParam =
              const fb.ListReader<double>(fb.Float64Reader(), lazy: false)
                  .vTableGetNullable(buffer, rootOffset, 38);
          final lineRadiusParam = const fb.Float64Reader()
              .vTableGetNullable(buffer, rootOffset, 40);
          final customPolygonLatsParam =
              const fb.ListReader<double>(fb.Float64Reader(), lazy: false)
                  .vTableGetNullable(buffer, rootOffset, 42);
          final customPolygonLngsParam =
              const fb.ListReader<double>(fb.Float64Reader(), lazy: false)
                  .vTableGetNullable(buffer, rootOffset, 44);
          final object = ObjectBoxRecovery(
              refId: refIdParam,
              storeName: storeNameParam,
              creationTime: creationTimeParam,
              typeId: typeIdParam,
              minZoom: minZoomParam,
              maxZoom: maxZoomParam,
              startTile: startTileParam,
              endTile: endTileParam,
              rectNwLat: rectNwLatParam,
              rectNwLng: rectNwLngParam,
              rectSeLat: rectSeLatParam,
              rectSeLng: rectSeLngParam,
              circleCenterLat: circleCenterLatParam,
              circleCenterLng: circleCenterLngParam,
              circleRadius: circleRadiusParam,
              lineLats: lineLatsParam,
              lineLngs: lineLngsParam,
              lineRadius: lineRadiusParam,
              customPolygonLats: customPolygonLatsParam,
              customPolygonLngs: customPolygonLngsParam)
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        }),
    ObjectBoxStore: obx_int.EntityDefinition<ObjectBoxStore>(
        model: _entities[1],
        toOneRelations: (ObjectBoxStore object) => [],
        toManyRelations: (ObjectBoxStore object) => {
              obx_int.RelInfo<ObjectBoxTile>.toManyBacklink(1, object.id):
                  object.tiles
            },
        getId: (ObjectBoxStore object) => object.id,
        setId: (ObjectBoxStore object, int id) {
          object.id = id;
        },
        objectToFB: (ObjectBoxStore object, fb.Builder fbb) {
          final nameOffset = fbb.writeString(object.name);
          final metadataJsonOffset = fbb.writeString(object.metadataJson);
          fbb.startTable(8);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, nameOffset);
          fbb.addInt64(2, object.length);
          fbb.addInt64(3, object.size);
          fbb.addInt64(4, object.hits);
          fbb.addInt64(5, object.misses);
          fbb.addOffset(6, metadataJsonOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final nameParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final lengthParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final sizeParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final hitsParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0);
          final missesParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 14, 0);
          final metadataJsonParam =
              const fb.StringReader(asciiOptimization: true)
                  .vTableGet(buffer, rootOffset, 16, '');
          final object = ObjectBoxStore(
              name: nameParam,
              length: lengthParam,
              size: sizeParam,
              hits: hitsParam,
              misses: missesParam,
              metadataJson: metadataJsonParam)
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);
          obx_int.InternalToManyAccess.setRelInfo<ObjectBoxStore>(
              object.tiles,
              store,
              obx_int.RelInfo<ObjectBoxTile>.toManyBacklink(1, object.id));
          return object;
        }),
    ObjectBoxTile: obx_int.EntityDefinition<ObjectBoxTile>(
        model: _entities[2],
        toOneRelations: (ObjectBoxTile object) => [],
        toManyRelations: (ObjectBoxTile object) => {
              obx_int.RelInfo<ObjectBoxTile>.toMany(1, object.id): object.stores
            },
        getId: (ObjectBoxTile object) => object.id,
        setId: (ObjectBoxTile object, int id) {
          object.id = id;
        },
        objectToFB: (ObjectBoxTile object, fb.Builder fbb) {
          final urlOffset = fbb.writeString(object.url);
          final bytesOffset = fbb.writeListInt8(object.bytes);
          fbb.startTable(5);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, urlOffset);
          fbb.addOffset(2, bytesOffset);
          fbb.addInt64(3, object.lastModified.millisecondsSinceEpoch);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final urlParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final bytesParam = const fb.Uint8ListReader(lazy: false)
              .vTableGet(buffer, rootOffset, 8, Uint8List(0)) as Uint8List;
          final lastModifiedParam = DateTime.fromMillisecondsSinceEpoch(
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0));
          final object = ObjectBoxTile(
              url: urlParam, bytes: bytesParam, lastModified: lastModifiedParam)
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);
          obx_int.InternalToManyAccess.setRelInfo<ObjectBoxTile>(object.stores,
              store, obx_int.RelInfo<ObjectBoxTile>.toMany(1, object.id));
          return object;
        }),
    ObjectBoxRoot: obx_int.EntityDefinition<ObjectBoxRoot>(
        model: _entities[3],
        toOneRelations: (ObjectBoxRoot object) => [],
        toManyRelations: (ObjectBoxRoot object) => {},
        getId: (ObjectBoxRoot object) => object.id,
        setId: (ObjectBoxRoot object, int id) {
          object.id = id;
        },
        objectToFB: (ObjectBoxRoot object, fb.Builder fbb) {
          fbb.startTable(4);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.length);
          fbb.addInt64(2, object.size);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final lengthParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          final sizeParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final object = ObjectBoxRoot(length: lengthParam, size: sizeParam)
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        })
  };

  return obx_int.ModelDefinition(model, bindings);
}

/// [ObjectBoxRecovery] entity fields to define ObjectBox queries.
class ObjectBoxRecovery_ {
  /// See [ObjectBoxRecovery.id].
  static final id =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[0]);

  /// See [ObjectBoxRecovery.refId].
  static final refId =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[1]);

  /// See [ObjectBoxRecovery.storeName].
  static final storeName =
      obx.QueryStringProperty<ObjectBoxRecovery>(_entities[0].properties[2]);

  /// See [ObjectBoxRecovery.creationTime].
  static final creationTime =
      obx.QueryDateProperty<ObjectBoxRecovery>(_entities[0].properties[3]);

  /// See [ObjectBoxRecovery.minZoom].
  static final minZoom =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[4]);

  /// See [ObjectBoxRecovery.maxZoom].
  static final maxZoom =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[5]);

  /// See [ObjectBoxRecovery.startTile].
  static final startTile =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[6]);

  /// See [ObjectBoxRecovery.endTile].
  static final endTile =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[7]);

  /// See [ObjectBoxRecovery.typeId].
  static final typeId =
      obx.QueryIntegerProperty<ObjectBoxRecovery>(_entities[0].properties[8]);

  /// See [ObjectBoxRecovery.rectNwLat].
  static final rectNwLat =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[9]);

  /// See [ObjectBoxRecovery.rectNwLng].
  static final rectNwLng =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[10]);

  /// See [ObjectBoxRecovery.rectSeLat].
  static final rectSeLat =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[11]);

  /// See [ObjectBoxRecovery.rectSeLng].
  static final rectSeLng =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[12]);

  /// See [ObjectBoxRecovery.circleCenterLat].
  static final circleCenterLat =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[13]);

  /// See [ObjectBoxRecovery.circleCenterLng].
  static final circleCenterLng =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[14]);

  /// See [ObjectBoxRecovery.circleRadius].
  static final circleRadius =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[15]);

  /// See [ObjectBoxRecovery.lineLats].
  static final lineLats = obx.QueryDoubleVectorProperty<ObjectBoxRecovery>(
      _entities[0].properties[16]);

  /// See [ObjectBoxRecovery.lineLngs].
  static final lineLngs = obx.QueryDoubleVectorProperty<ObjectBoxRecovery>(
      _entities[0].properties[17]);

  /// See [ObjectBoxRecovery.lineRadius].
  static final lineRadius =
      obx.QueryDoubleProperty<ObjectBoxRecovery>(_entities[0].properties[18]);

  /// See [ObjectBoxRecovery.customPolygonLats].
  static final customPolygonLats =
      obx.QueryDoubleVectorProperty<ObjectBoxRecovery>(
          _entities[0].properties[19]);

  /// See [ObjectBoxRecovery.customPolygonLngs].
  static final customPolygonLngs =
      obx.QueryDoubleVectorProperty<ObjectBoxRecovery>(
          _entities[0].properties[20]);
}

/// [ObjectBoxStore] entity fields to define ObjectBox queries.
class ObjectBoxStore_ {
  /// See [ObjectBoxStore.id].
  static final id =
      obx.QueryIntegerProperty<ObjectBoxStore>(_entities[1].properties[0]);

  /// See [ObjectBoxStore.name].
  static final name =
      obx.QueryStringProperty<ObjectBoxStore>(_entities[1].properties[1]);

  /// See [ObjectBoxStore.length].
  static final length =
      obx.QueryIntegerProperty<ObjectBoxStore>(_entities[1].properties[2]);

  /// See [ObjectBoxStore.size].
  static final size =
      obx.QueryIntegerProperty<ObjectBoxStore>(_entities[1].properties[3]);

  /// See [ObjectBoxStore.hits].
  static final hits =
      obx.QueryIntegerProperty<ObjectBoxStore>(_entities[1].properties[4]);

  /// See [ObjectBoxStore.misses].
  static final misses =
      obx.QueryIntegerProperty<ObjectBoxStore>(_entities[1].properties[5]);

  /// See [ObjectBoxStore.metadataJson].
  static final metadataJson =
      obx.QueryStringProperty<ObjectBoxStore>(_entities[1].properties[6]);
}

/// [ObjectBoxTile] entity fields to define ObjectBox queries.
class ObjectBoxTile_ {
  /// See [ObjectBoxTile.id].
  static final id =
      obx.QueryIntegerProperty<ObjectBoxTile>(_entities[2].properties[0]);

  /// See [ObjectBoxTile.url].
  static final url =
      obx.QueryStringProperty<ObjectBoxTile>(_entities[2].properties[1]);

  /// See [ObjectBoxTile.bytes].
  static final bytes =
      obx.QueryByteVectorProperty<ObjectBoxTile>(_entities[2].properties[2]);

  /// See [ObjectBoxTile.lastModified].
  static final lastModified =
      obx.QueryDateProperty<ObjectBoxTile>(_entities[2].properties[3]);

  /// see [ObjectBoxTile.stores]
  static final stores = obx.QueryRelationToMany<ObjectBoxTile, ObjectBoxStore>(
      _entities[2].relations[0]);
}

/// [ObjectBoxRoot] entity fields to define ObjectBox queries.
class ObjectBoxRoot_ {
  /// See [ObjectBoxRoot.id].
  static final id =
      obx.QueryIntegerProperty<ObjectBoxRoot>(_entities[3].properties[0]);

  /// See [ObjectBoxRoot.length].
  static final length =
      obx.QueryIntegerProperty<ObjectBoxRoot>(_entities[3].properties[1]);

  /// See [ObjectBoxRoot.size].
  static final size =
      obx.QueryIntegerProperty<ObjectBoxRoot>(_entities[3].properties[2]);
}
