// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';
import '../db/defs/tile.dart';
import '../db/registry.dart';
import '../db/tools.dart';
import 'bulk_tile_writer.dart';
import 'internal_timing_progress_management.dart';
import 'tile_loops/shared.dart';
import 'tile_progress.dart';

@internal
Future<Stream<TileProgress>> bulkDownloader({
  required StreamController<TileProgress> streamController,
  required Completer<void> cancelRequestSignal,
  required Completer<void> cancelCompleteSignal,
  required DownloadableRegion region,
  required FMTCTileProvider provider,
  required Uint8List? seaTileBytes,
  required InternalProgressTimingManagement progressManagement,
  required BaseClient client,
}) async {
  final tiles = FMTCRegistry.instance(provider.storeDirectory.storeName);

  final recievePort = ReceivePort();
  final sendPort = recievePort.sendPort;
  final tileIsolate = await Isolate.spawn(
    region.type == RegionType.rectangle
        ? TilesGenerator.rectangleTiles
        : region.type == RegionType.circle
            ? TilesGenerator.circleTiles
            : TilesGenerator.lineTiles,
    {'sendPort': sendPort, ...generateTileLoopsInput(region)},
    onExit: sendPort,
  );
  final tileQueue = StreamQueue(
    recievePort.skip(region.start).take(
          region.end == null
              ? 9223372036854775807
              : (region.end! - region.start),
        ),
  );

  final threadStates = List.generate(
    region.parallelThreads + 1,
    (_) => Completer<void>(),
    growable: false,
  );

  for (int thread = 0; thread <= region.parallelThreads; thread++) {
    unawaited(() async {
      while (true) {
        final List<int>? value;

        try {
          value = await tileQueue.next;
          // ignore: avoid_catching_errors
        } on StateError {
          threadStates[thread].complete();
          break;
        }

        if (cancelRequestSignal.isCompleted) {
          await tileQueue.cancel(immediate: true);

          tileIsolate.kill(priority: Isolate.immediate);
          recievePort.close();

          await BulkTileWriter.stop(null);
          unawaited(streamController.close());

          cancelCompleteSignal.complete();
          break;
        }

        if (value == null) {
          await tileQueue.cancel();

          threadStates[thread].complete();
          await Future.wait(threadStates.map((e) => e.future));

          recievePort.close();

          await BulkTileWriter.stop(null);
          unawaited(streamController.close());

          break;
        }

        final coord = TileCoordinates(value[0], value[1], value[2]);

        final url = provider.getTileUrl(coord, region.options);
        final existingTile = await tiles.tiles.get(DatabaseTools.hash(url));

        try {
          final List<int> bytes = [];

          if (region.preventRedownload && existingTile != null) {
            streamController.add(
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

          final uri = Uri.parse(url);
          final response = await client
              .send(Request('GET', uri)..headers.addAll(provider.headers));

          if (response.statusCode != 200) {
            throw HttpException(
              response.reasonPhrase ?? response.statusCode.toString(),
              uri: uri,
            );
          }

          int received = 0;
          await for (final List<int> evt in response.stream) {
            bytes.addAll(evt);
            received += evt.length;
            progressManagement.progress[url.hashCode] = TimestampProgress(
              DateTime.now(),
              received / (response.contentLength ?? 0),
            );
          }

          if (existingTile != null &&
              seaTileBytes != null &&
              const ListEquality().equals(bytes, seaTileBytes)) {
            streamController.add(
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

          streamController.add(
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
          if (!streamController.isClosed) {
            streamController.add(
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

  return streamController.stream;
}
