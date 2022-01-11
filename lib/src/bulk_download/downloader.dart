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

Stream<List> bulkDownloader({
  required List<Coords<num>> tiles,
  required StorageCachingTileProvider provider,
  required TileLayerOptions options,
  required http.Client client,
  required Function(dynamic)? errorHandler,
  required int parallelThreads,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
  required Queue queue,
  required StreamController<List> streamController,
}) {
  for (var coord in tiles) {
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
      (value) {
        if (!streamController.isClosed) {
          streamController.add(
            [
              value[0],
              value[1],
              value[2],
              value[3],
            ],
          );
        }
      },
    );
  }

  return streamController.stream;
}

Future<List<dynamic>> _getAndSaveTile({
  required StorageCachingTileProvider provider,
  required Coords<num> coord,
  required TileLayerOptions options,
  required http.Client client,
  required Function(dynamic)? errorHandler,
  required bool preventRedownload,
  required Uint8List? seaTileBytes,
}) async {
  final Coords<double> coordDouble =
      Coords(coord.x.toDouble(), coord.y.toDouble())..z = coord.z.toDouble();
  final String url = provider.getTileUrl(coordDouble, options);
  final String path = p.joinAll([
    provider.storeDirectory.absolute.path,
    safeFilesystemString(inputString: url, throwIfInvalid: false),
  ]);

  try {
    if (preventRedownload && await File(path).exists()) return [1, '', 0, 1];

    File(path).writeAsBytesSync(
      (await client.get(Uri.parse(url))).bodyBytes,
      flush: true,
    );

    if (seaTileBytes != null &&
        const ListEquality()
            .equals(await File(path).readAsBytes(), seaTileBytes)) {
      await File(path).delete();
      return [1, '', 1, 0];
    }
  } catch (e) {
    if (errorHandler != null) errorHandler(e);
    return [0, url, 0, 0];
  }

  return [1, '', 0, 0];
}
