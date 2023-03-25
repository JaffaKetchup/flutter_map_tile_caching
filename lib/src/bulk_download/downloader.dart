// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../flutter_map_tile_caching.dart';
import '../db/defs/tile.dart';
import '../db/registry.dart';
import '../db/tools.dart';
import 'bulk_tile_writer.dart';
import 'internal_timing_progress_management.dart';
import 'tile_loops/shared.dart';
import 'tile_progress.dart';

//! ENTRY POINT !//

@internal
Future<Stream<TileProgress>> bulkDownloader({
  required DownloadableRegion region,
  required FMTCTileProvider provider,
  required StreamController<TileProgress> tileProgressStreamController,
  required Stream<void> cancelStream,
  required BaseClient client,
  required Uint8List? seaTileBytes,
  required InternalProgressTimingManagement progressManagement,
}) async {
  final tiles = FMTCRegistry.instance(provider.storeDirectory.storeName);

  final isolatePort = ReceivePort();
  final tileIsolate = await Isolate.spawn(
    region.type == RegionType.rectangle
        ? TilesGenerator.rectangleTiles
        : region.type == RegionType.circle
            ? TilesGenerator.circleTiles
            : TilesGenerator.lineTiles,
    {'sendPort': isolatePort.sendPort, ...generateTileLoopsInput(region)},
  );
  final tileQueue = StreamQueue<List<int>?>(
    isolatePort
        .skip(region.start)
        .take(
          region.end == null
              ? 9223372036854775807
              : (region.end! - region.start),
        )
        .merge(cancelStream)
        .cast(),
  );

  for (int _ = 1; _ <= region.parallelThreads; _++) {
    unawaited(() async {
      while (true) {
        final List<int>? value;

        try {
          value = await tileQueue.next;
          // ignore: avoid_catching_errors
        } on StateError {
          break;
        }

        if (value == null) {
          tileIsolate.kill(priority: Isolate.immediate);
          isolatePort.close();
          unawaited(tileProgressStreamController.close());
          await tileQueue.cancel(immediate: true);
          break;
        }

        final coord = Coords(value[0], value[1])..z = value[2];

        final url = provider.getTileUrl(coord, region.options);
        final existingTile = await tiles.tiles.get(DatabaseTools.hash(url));

        try {
          final List<int> bytes = [];

          if (region.preventRedownload && existingTile != null) {
            tileProgressStreamController.add(
              TileProgress(
                failedUrl: null,
                tileImage: null,
                wasSeaTile: false,
                wasExistingTile: true,
                wasCancelOperation: false,
                bulkTileWriterResponse: null,
              ),
            );
          }

          final response = await client.send(
            Request('GET', Uri.parse(url))..headers.addAll(provider.headers),
          );
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
            tileProgressStreamController.add(
              TileProgress(
                failedUrl: null,
                tileImage: Uint8List.fromList(bytes),
                wasSeaTile: true,
                wasExistingTile: false,
                wasCancelOperation: false,
                bulkTileWriterResponse: null,
              ),
            );
          }

          BulkTileWriter.instance.sendPort.send(
            List.unmodifiable(
              [provider.settings.obscureQueryParams(url), bytes],
            ),
          );

          tileProgressStreamController.add(
            TileProgress(
              failedUrl: null,
              tileImage: Uint8List.fromList(bytes),
              wasSeaTile: false,
              wasExistingTile: false,
              wasCancelOperation: false,
              bulkTileWriterResponse: await BulkTileWriter.instance.events.next,
            ),
          );
        } catch (e) {
          region.errorHandler?.call(e);
          if (!tileProgressStreamController.isClosed) {
            tileProgressStreamController.add(
              TileProgress(
                failedUrl: url,
                tileImage: null,
                wasSeaTile: false,
                wasExistingTile: false,
                wasCancelOperation: false,
                bulkTileWriterResponse: null,
              ),
            );
          }
        }
      }
    }());
  }

  return tileProgressStreamController.stream;
}
