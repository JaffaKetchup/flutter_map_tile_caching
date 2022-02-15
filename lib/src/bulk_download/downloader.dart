import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p show joinAll;
import 'package:queue/queue.dart';

import '../main.dart';
import '../misc/validate.dart';
import 'tile_progress.dart';

Stream<TileProgress> bulkDownloader({
  required List<Coords<num>> tiles,
  required StorageCachingTileProvider provider,
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
  required StorageCachingTileProvider provider,
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
  final String path = p.joinAll([
    provider.storeDirectory.absolute.path,
    safeFilesystemString(inputString: url, throwIfInvalid: false),
  ]);

  try {
    if (preventRedownload && await File(path).exists()) {
      return TileProgress(
        failedUrl: null,
        wasSeaTile: false,
        wasExistingTile: true,
        duration: calcElapsed(),
      );
    }

    File(path).writeAsBytesSync(
      (await client.get(Uri.parse(url))).bodyBytes,
      flush: true,
    );

    if (seaTileBytes != null &&
        const ListEquality()
            .equals(await File(path).readAsBytes(), seaTileBytes)) {
      await File(path).delete();
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
