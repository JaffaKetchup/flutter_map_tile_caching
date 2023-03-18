// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:queue/queue.dart';

import '../../flutter_map_tile_caching.dart';
import '../db/defs/tile.dart';
import '../db/registry.dart';
import '../db/tools.dart';
import 'bulk_tile_writer.dart';
import 'internal_timing_progress_management.dart';
import 'tile_progress.dart';

//! ENTRY POINT !//

@internal
Stream<TileProgress> bulkDownloader({
  required Iterable<Coords<num>> tiles,
  required FMTCTileProvider provider,
  required TileLayer options,
  required BaseClient client,
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
    }).catchError((_) {});
  }

  return streamController.stream;
}

//! DOWNLOAD AND SAVE TILE !//

Future<TileProgress> _getAndSaveTile({
  required FMTCTileProvider provider,
  required Coords<num> coord,
  required TileLayer options,
  required BaseClient client,
  required void Function(Object)? errorHandler,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required int downloadID,
  required InternalProgressTimingManagement progressManagement,
}) async {
  final Isar tiles = FMTCRegistry.instance(provider.storeDirectory.storeName);

  final String url = provider.getTileUrl(coord, options);
  final DbTile? existingTile = await tiles.tiles.get(DatabaseTools.hash(url));

  final List<int> bytes = [];
  final List<int>? bulkTileWriterResponse;

  try {
    if (preventRedownload && existingTile != null) {
      return TileProgress(
        failedUrl: null,
        tileImage: null,
        wasSeaTile: false,
        wasExistingTile: true,
        wasCancelOperation: false,
        bulkTileWriterResponse: null,
      );
    }

    final response = await client
        .send(Request('GET', Uri.parse(url))..headers.addAll(provider.headers));
    final totalBytes = response.contentLength ?? 0;

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
        tileImage: Uint8List.fromList(bytes),
        wasSeaTile: true,
        wasExistingTile: false,
        wasCancelOperation: false,
        bulkTileWriterResponse: null,
      );
    }

    BulkTileWriter.instance.sendPort.send(
      List.unmodifiable([provider.settings.obscureQueryParams(url), bytes]),
    );
    bulkTileWriterResponse = await BulkTileWriter.instance.events.next;
  } catch (e) {
    if (errorHandler != null) errorHandler(e);
    return TileProgress(
      failedUrl: url,
      tileImage: null,
      wasSeaTile: false,
      wasExistingTile: false,
      wasCancelOperation: false,
      bulkTileWriterResponse: null,
    );
  }

  return TileProgress(
    failedUrl: null,
    tileImage: Uint8List.fromList(bytes),
    wasSeaTile: false,
    wasExistingTile: false,
    wasCancelOperation: false,
    bulkTileWriterResponse: bulkTileWriterResponse,
  );
}
