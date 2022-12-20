// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// Why is this file so convoluted? To maximise write performance.

import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:queue/queue.dart';
import 'package:stream_isolate/stream_isolate.dart';

import '../db/defs/metadata.dart';
import '../db/defs/tile.dart';
import '../db/registry.dart';
import '../db/tools.dart';
import '../providers/tile_provider.dart';
import 'internal_timing_progress_management.dart';
import 'tile_progress.dart';

//! ENTRY POINT !//

@internal
Stream<TileProgress> bulkDownloader({
  required List<Coords<num>> tiles,
  required FMTCTileProvider provider,
  required TileLayer options,
  required http.Client client,
  required Function(Object?)? errorHandler,
  required int parallelThreads,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required Queue queue,
  required StreamController<TileProgress> streamController,
  required int downloadID,
  required InternalProgressTimingManagement progressManagement,
}) {
  for (final Coords<num> coord in tiles) {
    queue
        .add(
      () => _getAndSaveTile(
        provider: provider,
        coord: coord,
        options: options,
        client: client,
        errorHandler: errorHandler,
        preventRedownload: preventRedownload,
        seaTileBytes: seaTileBytes,
        downloadID: downloadID,
        progressManagement: progressManagement,
      ),
    )
        .then((e) {
      if (!streamController.isClosed) streamController.add(e);
    });
  }

  return streamController.stream;
}

//! DOWNLOAD AND SAVE TILE !//

Future<TileProgress> _getAndSaveTile({
  required FMTCTileProvider provider,
  required Coords<num> coord,
  required TileLayer options,
  required http.Client client,
  required void Function(Object)? errorHandler,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required int downloadID,
  required InternalProgressTimingManagement progressManagement,
}) async {
  final Isar tiles = FMTCRegistry.instance
      .tileDatabases[DatabaseTools.hash(provider.storeDirectory.storeName)]!;

  final String url = provider.getTileUrl(coord, options);
  final DbTile? existingTile = await tiles.tiles.get(DatabaseTools.hash(url));

  final List<int> bytes = [];

  try {
    if (preventRedownload && existingTile != null) {
      return TileProgress(
        failedUrl: null,
        wasSeaTile: false,
        wasExistingTile: true,
        tileImage: null,
      );
    }

    final http.StreamedResponse response =
        await client.send(http.Request('GET', Uri.parse(url)));
    final int totalBytes = response.contentLength ?? 0;

    int received = 0;
    await for (final List<int> evt in response.stream) {
      bytes.addAll(evt);
      received += evt.length;
      progressManagement.progress[url.hashCode] = TimestampProgress(
        DateTime.now(),
        received / totalBytes,
      );
    }

    if (existingTile != null &&
        seaTileBytes != null &&
        const ListEquality().equals(bytes, seaTileBytes)) {
      return TileProgress(
        failedUrl: null,
        wasSeaTile: true,
        wasExistingTile: false,
        tileImage: Uint8List.fromList(bytes),
      );
    }

    BulkTileWriter.instance!.isolate.send([url, bytes]);
  } catch (e) {
    if (errorHandler != null) errorHandler(e);
    return TileProgress(
      failedUrl: url,
      wasSeaTile: false,
      wasExistingTile: false,
      tileImage: null,
    );
  }

  return TileProgress(
    failedUrl: null,
    wasSeaTile: false,
    wasExistingTile: false,
    tileImage: Uint8List.fromList(bytes),
  );
}

//! BULK TILE WRITER !//

@internal
class BulkTileWriter {
  BulkTileWriter._();
  static BulkTileWriter? instance;

  late BidirectionalStreamIsolate<List<Object>, void> isolate;

  static Future<void> start(FMTCTileProvider provider) async {
    instance = BulkTileWriter._();
    instance!.isolate =
        await StreamIsolate.spawnBidirectional(_bulkTileWriterWorker);
    instance!.isolate.send([provider.storeDirectory.storeName]);
  }

  static void stop() {
    instance!.isolate.close();
    instance = null;
  }
}

Stream<void> _bulkTileWriterWorker(
  Stream<List<Object>> stream,
  _,
) async* {
  Isar? db;

  await for (final info in stream) {
    if (db == null) {
      db = Isar.openSync(
        [DbTileSchema, DbMetadataSchema],
        name: DatabaseTools.hash(info[0].toString()).toString(),
      );
    } else {
      db.writeTxnSync(
        () => db!.tiles.putSync(
          DbTile(
            url: info[0] as String,
            bytes: info[1] as List<int>,
          ),
        ),
      );
    }
  }
}
