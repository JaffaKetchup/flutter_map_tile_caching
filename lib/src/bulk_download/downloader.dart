import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:queue/queue.dart';

import '../internal/exts.dart';
import '../internal/tile_provider.dart';
import '../main.dart';
import '../misc/validate.dart';
import 'tile_progress.dart';

Stream<TileProgress> bulkDownloader({
  required List<Coords<num>> tiles,
  required FMTCTileProvider provider,
  required TileLayerOptions options,
  required http.Client client,
  required Function(dynamic)? errorHandler,
  required int parallelThreads,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required Queue queue,
  required StreamController<TileProgress> streamController,
}) {
  for (Coords<num> coord in tiles) {
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
  required Function(dynamic)? errorHandler,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
}) async {
  final DateTime startTime = DateTime.now();
  Duration calcElapsed() => DateTime.now().difference(startTime);

  final Coords<double> coordDouble =
      Coords(coord.x.toDouble(), coord.y.toDouble())..z = coord.z.toDouble();
  final String url = provider.getTileUrl(coordDouble, options);
  final File file = provider.storeDirectory.access.tiles >>>
      safeFilesystemString(inputString: url, throwIfInvalid: false);

  try {
    if (preventRedownload && await file.exists()) {
      return TileProgress(
        failedUrl: null,
        wasSeaTile: false,
        wasExistingTile: true,
        duration: calcElapsed(),
      );
    }

    file.writeAsBytesSync(
      (await client.get(Uri.parse(url))).bodyBytes,
      flush: true,
    );

    if (seaTileBytes != null &&
        const ListEquality().equals(await file.readAsBytes(), seaTileBytes)) {
      await file.delete();
      return TileProgress(
        failedUrl: null,
        wasSeaTile: true,
        wasExistingTile: false,
        duration: calcElapsed(),
      );
    }
  } catch (e) {
    if (errorHandler != null) errorHandler(e);
    return TileProgress(
      failedUrl: url,
      wasSeaTile: false,
      wasExistingTile: false,
      duration: calcElapsed(),
    );
  }

  return TileProgress(
    failedUrl: null,
    wasSeaTile: false,
    wasExistingTile: false,
    duration: DateTime.now().difference(startTime),
  );
}
