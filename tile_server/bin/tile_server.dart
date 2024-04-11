// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:jaguar/jaguar.dart';

import '../static/generated/favicon.dart';
import '../static/generated/land.dart';
import '../static/generated/sea.dart';

Future<void> main(List<String> _) async {
  // Initialise console
  final console = Console()
    ..hideCursor()
    ..setTextStyle(bold: true, underscore: true)
    ..write('\nFMTC Testing Tile Server\n')
    ..setTextStyle()
    ..write('© Luka S (JaffaKetchup)\n')
    ..write(
      "Miniature fake tile server designed to test FMTC's throughput and download speeds\n\n",
    );

  // Monitor requests per second measurement (tps)
  final requestTimestamps = <DateTime>[];
  var lastRate = 0;
  Timer.periodic(const Duration(seconds: 1), (_) {
    lastRate = requestTimestamps.length;
    requestTimestamps.clear();
  });

  // Setup artificial delay
  const artificialDelayChangeAmount = Duration(milliseconds: 2);
  Duration currentArtificialDelay = Duration.zero;

  // Track number of sea tiles served
  int servedSeaTiles = 0;

  // Initialise HTTP server
  final server = Jaguar(
    multiThread: true,
    onRouteServed: (ctx) {
      final requestTime = ctx.at;
      requestTimestamps.add(requestTime);
      console.write(
        '[$requestTime] ${ctx.method} ${ctx.path}: ${ctx.response.statusCode}\t\t$servedSeaTiles sea tiles this session\t\t\t$lastRate tps  -  ${currentArtificialDelay.inMilliseconds} ms delay\n',
      );
    },
    port: 7070,
  );

  // Handle keyboard events
  final keyboardHandlerreceivePort = ReceivePort();
  await Isolate.spawn(
    (sendPort) {
      while (true) {
        final key = Console().readKey();

        if (key.char.toLowerCase() == 'q') Isolate.exit();

        if (key.controlChar == ControlCharacter.arrowUp) sendPort.send(1);
        if (key.controlChar == ControlCharacter.arrowDown) sendPort.send(-1);
      }
    },
    keyboardHandlerreceivePort.sendPort,
    onExit: keyboardHandlerreceivePort.sendPort,
  );
  keyboardHandlerreceivePort.listen(
    (message) =>
        // Control artificial delay
        currentArtificialDelay += artificialDelayChangeAmount * message,
    // Stop server and quit
    onDone: () {
      server.close();
      console
        ..setTextStyle(bold: true)
        ..write('\n\nKilled HTTP server\n')
        ..setTextStyle()
        ..showCursor();
      exit(0);
    },
  );

  // Preload responses
  final faviconReponse = ByteResponse(
    body: faviconTileBytes,
    mimeType: 'image/vnd.microsoft.icon',
  );
  final landTileResponse = ByteResponse(
    body: landTileBytes,
    mimeType: MimeTypes.png,
  );
  final seaTileResponse = ByteResponse(
    body: seaTileBytes,
    mimeType: MimeTypes.png,
  );

  // Initialise random chance for sea/land tile (1:10)
  final random = Random();

  server
    // Serve 'favicon.ico'
    ..get('/favicon.ico', (_) => faviconReponse)
    // Serve tiles to all other requests
    ..get(
      '/:z/:x/:y',
      (ctx) async {
        // Get tile request segments
        final z = ctx.pathParams.getInt('z', -1)!;
        final x = ctx.pathParams.getInt('x', -1)!;
        final y = ctx.pathParams.getInt('y', -1)!;

        // Check if tile request is inside valid range
        if (x < 0 || y < 0 || z < 0) {
          return Response(statusCode: 400);
        }
        final maxTileNum = sqrt(pow(4, z)) - 1;
        if (x > maxTileNum || y > maxTileNum) {
          return Response(statusCode: 400);
        }

        // Create artificial delay if applicable
        if (currentArtificialDelay > Duration.zero) {
          await Future.delayed(currentArtificialDelay);
        }

        // Serve either sea or land tile
        if (ctx.path == '/17/0/0' || random.nextInt(10) == 0) {
          servedSeaTiles += 1;
          return seaTileResponse;
        }
        return landTileResponse;
      },
    );

  // Output basic console instructions
  console
    ..setTextStyle(italic: true)
    ..write('Now serving tiles at 127.0.0.1:7070/{z}/{x}/{y}\n\n')
    ..write("Press 'q' to kill server\n")
    ..write(
      'Press UP or DOWN to manipulate artificial delay by ${artificialDelayChangeAmount.inMilliseconds} ms\n\n',
    )
    ..setTextStyle()
    ..write('----------\n');

  // Start HTTP server
  await server.serve(logRequests: true);
}
