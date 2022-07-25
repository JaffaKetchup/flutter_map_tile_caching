import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:queue/queue.dart';

import '../internal/exts.dart';
import '../internal/tile_provider.dart';
import '../settings/filesystem_sanitiser_private.dart';
import 'progress_management.dart';
import 'tile_progress.dart';

Stream<TileProgress> bulkDownloader({
  required List<Coords<num>> tiles,
  required FMTCTileProvider provider,
  required TileLayerOptions options,
  required http.Client client,
  required Function(Object?)? errorHandler,
  required int parallelThreads,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required Queue queue,
  required StreamController<TileProgress> streamController,
  required int downloadID,
  required ProgressManagement progressManagement,
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
        .then(
      (e) {
        if (!streamController.isClosed) streamController.add(e);
      },
    );
  }

  return streamController.stream;
}

Future<TileProgress> _getAndSaveTile({
  required FMTCTileProvider provider,
  required Coords<num> coord,
  required TileLayerOptions options,
  required http.Client client,
  required void Function(Object)? errorHandler,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required int downloadID,
  required ProgressManagement progressManagement,
}) async {
  final Coords<double> coordDouble =
      Coords(coord.x.toDouble(), coord.y.toDouble())..z = coord.z.toDouble();
  final String url = provider.getTileUrl(coordDouble, options);
  final File file = provider.storeDirectory.access.tiles >>>
      filesystemSanitiseValidate(
        inputString: url,
        throwIfInvalid: false,
      );

  final List<int> bytes = [];

  try {
    if (preventRedownload && await file.exists()) {
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

    final Stream<List<int>> stream = response.stream.asBroadcastStream()
      ..listen((eventBytes) {
        bytes.addAll(eventBytes);
        received += eventBytes.length;
        progressManagement.progress.add(
          TileTimestampProgress(
            url,
            DateTime.now(),
            received / totalBytes,
          ),
        );
      });

    await stream.last;

    file.writeAsBytesSync(
      bytes,
      flush: true,
    );

    if (seaTileBytes != null &&
        const ListEquality().equals(await file.readAsBytes(), seaTileBytes)) {
      await file.delete();
      return TileProgress(
        failedUrl: null,
        wasSeaTile: true,
        wasExistingTile: false,
        tileImage: Uint8List.fromList(bytes),
      );
    }
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
