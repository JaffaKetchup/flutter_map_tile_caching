// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';
import '../db/defs/metadata.dart';
import '../db/defs/store_descriptor.dart';
import '../db/defs/tile.dart';
import '../db/tools.dart';
import 'tile_progress.dart';

/// Handles tile writing during a bulk download
///
/// Note that this is designed for performance, relying on isolate workers to
/// carry out expensive operations.
@internal
class BulkTileWriter {
  BulkTileWriter._();

  static BulkTileWriter? _instance;
  static BulkTileWriter get instance => _instance!;

  late ReceivePort _recievePort;
  late DownloadBufferMode _bufferMode;
  late StreamController<TileProgress> _downloadStream;

  late SendPort sendPort;
  late StreamQueue<dynamic> events;

  static Future<void> start({
    required FMTCTileProvider provider,
    required DownloadBufferMode bufferMode,
    required int? bufferLimit,
    required String directory,
    required StreamController<TileProgress> streamController,
  }) async {
    final btw = BulkTileWriter._()
      .._recievePort = ReceivePort()
      .._bufferMode = bufferMode
      .._downloadStream = streamController;

    await Isolate.spawn(
      bufferMode == DownloadBufferMode.disabled
          ? _instantWorker
          : _bufferWorker,
      btw._recievePort.sendPort,
    );

    btw
      ..events = StreamQueue(btw._recievePort)
      ..sendPort = await btw.events.next
      ..sendPort.send(
        bufferMode == DownloadBufferMode.disabled
            ? [
                provider.storeDirectory.storeName,
                directory,
              ]
            : [
                provider.storeDirectory.storeName,
                directory,
                bufferMode,
                bufferLimit ??
                    (bufferMode == DownloadBufferMode.tiles ? 500 : 2000000),
              ],
      );

    _instance = btw;
  }

  static Future<void> stop(Uint8List? tileImage) async {
    if (_instance == null) return;

    instance.sendPort.send(null);
    if (instance._bufferMode != DownloadBufferMode.disabled) {
      instance._downloadStream.add(
        TileProgress(
          failedUrl: null,
          tileImage: tileImage,
          wasSeaTile: false,
          wasExistingTile: false,
          wasCancelOperation: true,
          bulkTileWriterResponse: await instance.events.next,
        ),
      );
    }
    await instance.events.cancel(immediate: true);

    _instance = null;
  }
}

/// Isolate ('worker') for [BulkTileWriter] that supports buffered tile writing
///
/// Starting this worker will send its recieve port to the specified [sendPort],
/// to be used for further communication, as described below:
///
/// The first incoming message is expected to contain setup information, namely
/// the store name that will be targeted, the buffer mode, and the buffer limit,
/// as a list. No response is sent to this message.
///
/// Following incoming messages are expected to either contain tile information
/// or to signal the end of the worker's lifespan. Should the message not be
/// null, a list will be expected where the first element is the tile URL and the
/// second element is the tile bytes. Should the message be null, the worker will
/// be terminated as described below. Responses are defined below.
///
/// On reciept of a tile descriptor, it will be added to the buffer. If the total
/// buffer size then exceeds the limit defined in the setup message, the buffer
/// will be written to the database, then cleared. In this case, the response
/// will be a list of the total number of tiles and the total number of bytes
/// now written to the database. If the limit is not exceeded, the tile will not
/// be written, and the response will be null, indicating that there is no more
/// information, but the tile was processed correctly.
///
/// On reciept of the `null` termination message, the buffer will be written,
/// regardless of it's length. This worker will then be killed, with a response
/// of the total number of tiles written, regardless of whether any tiles were
/// just written.
///
/// It is illegal to kill this isolate externally, as this may lead to data loss.
/// Always terminate by sending the termination (`null`) message.
///
/// It is illegal to send corrupted/invalid/unknown messages, as this will likely
/// crash the worker, leading to data loss. No validation is performed on
/// incoming data.
Future<void> _bufferWorker(SendPort sendPort) async {
  final rp = ReceivePort();
  sendPort.send(rp.sendPort);
  final recievePort = rp.asBroadcastStream();

  final setupInfo = await recievePort.first as List<dynamic>;
  final db = Isar.openSync(
    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
    name: DatabaseTools.hash(setupInfo[0]).toString(),
    directory: setupInfo[1],
    inspector: false,
  );

  final bufferMode = setupInfo[2] as DownloadBufferMode;
  final bufferLimit = setupInfo[3] as int;

  final tileBuffer = <DbTile>{};

  int totalTilesWritten = 0;
  int totalBytesWritten = 0;

  int currentTilesBuffered = 0;
  int currentBytesBuffered = 0;

  void writeBuffer() {
    db.writeTxnSync(() => tileBuffer.forEach(db.tiles.putSync));

    totalBytesWritten += currentBytesBuffered;
    totalTilesWritten += currentTilesBuffered;

    tileBuffer.clear();
    currentBytesBuffered = 0;
    currentTilesBuffered = 0;
  }

  recievePort.where((i) => i == null).listen((_) {
    writeBuffer();
    Isolate.exit(sendPort, [totalTilesWritten, totalBytesWritten]);
  });
  recievePort.where((i) => i != null).listen((info) {
    currentBytesBuffered += Uint8List.fromList((info as List)[1]).lengthInBytes;
    currentTilesBuffered++;
    tileBuffer.add(DbTile(url: info[0], bytes: info[1]));
    if ((bufferMode == DownloadBufferMode.tiles
            ? currentTilesBuffered
            : currentBytesBuffered) >
        bufferLimit) {
      writeBuffer();
      sendPort.send([totalTilesWritten, totalBytesWritten]);
    } else {
      sendPort.send(null);
    }
  });
}

/// Isolate ('worker') for [BulkTileWriter] that doesn't supports buffered tile
/// writing
///
/// Starting this worker will send its recieve port to the specified [sendPort],
/// to be used for further communication, as described below:
///
/// The first incoming message is expected to contain setup information, namely
/// the store name that will be targeted. No response is sent to this message.
///
/// Following incoming messages are expected to either contain tile information
/// or to signal the end of the worker's lifespan. Should the message not be
/// null, a list will be expected where the first element is the tile URL and the
/// second element is the tile bytes. Should the message be null, the worker will
/// be terminated immediatley without a response.
///
/// On reciept of a tile descriptor, the tile will be written to the database,
/// and the response will be `null`.
///
/// It is not recommended to kill this isolate externally. Prefer termination by
/// sending the termination (`null`) message.
///
/// It is illegal to send corrupted/invalid/unknown messages, as this will likely
/// crash the worker, leading to data loss. No validation is performed on
/// incoming data.
Future<void> _instantWorker(SendPort sendPort) async {
  final rp = ReceivePort();
  sendPort.send(rp.sendPort);
  final recievePort = rp.asBroadcastStream();

  final setupInfo = await recievePort.first as List<dynamic>;
  final db = Isar.openSync(
    [DbStoreDescriptorSchema, DbTileSchema, DbMetadataSchema],
    name: DatabaseTools.hash(setupInfo[0]).toString(),
    directory: setupInfo[1],
    inspector: false,
  );

  recievePort.where((i) => i == null).listen((_) => Isolate.exit());
  recievePort.where((i) => i != null).listen((info) {
    db.writeTxnSync(
      () => db.tiles.putSync(DbTile(url: (info as List)[0], bytes: info[1])),
    );
    sendPort.send(null);
  });
}
