// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:jaguar/jaguar.dart';
import 'package:path/path.dart' as p;

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

  // Find path to '/static/' directory
  final execPath = p.split(Platform.script.toFilePath());
  final staticPath =
      p.joinAll([...execPath.getRange(0, execPath.length - 2), 'static']);

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
        '[$requestTime] ${ctx.method} ${ctx.path}\t\t$servedSeaTiles sea tiles\t\t\t$lastRate tps  -  ${currentArtificialDelay.inMilliseconds} ms delay\n',
      );
    },
  );

  // Handle keyboard events
  final keyboardHandlerRecievePort = ReceivePort();
  await Isolate.spawn(
    (sendPort) {
      while (true) {
        final key = Console().readKey();

        if (key.char.toLowerCase() == 'q') Isolate.exit();

        if (key.controlChar == ControlCharacter.arrowUp) sendPort.send(1);
        if (key.controlChar == ControlCharacter.arrowDown) sendPort.send(-1);
      }
    },
    keyboardHandlerRecievePort.sendPort,
    onExit: keyboardHandlerRecievePort.sendPort,
  );
  keyboardHandlerRecievePort.listen(
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

  // Preload tile responses
  final landTileResponse = ByteResponse(
    body: File(p.join(staticPath, 'tiles', 'land.png')).readAsBytesSync(),
    mimeType: MimeTypes.png,
  );
  final seaTileResponse = ByteResponse(
    body: File(p.join(staticPath, 'tiles', 'sea.png')).readAsBytesSync(),
    mimeType: MimeTypes.png,
  );

  // Initialise random chance for sea/land tile (1:10)
  final random = Random();

  server
    // Serve 'favicon.ico'
    ..staticFile('/favicon.ico', p.join(staticPath, 'favicon.ico'))
    // Serve tiles to all other requests
    ..get(
      '*',
      (ctx) async {
        // Create artificial delay if applicable
        if (currentArtificialDelay > Duration.zero) {
          await Future.delayed(currentArtificialDelay);
        }

        // Serve either sea or land tile
        if (ctx.path == '/17/0/0.png' || random.nextInt(10) == 0) {
          servedSeaTiles += 1;
          return seaTileResponse;
        }
        return landTileResponse;
      },
    );

  // Output basic console instructions
  console
    ..setTextStyle(italic: true)
    ..write('Now serving tiles to all requests to 127.0.0.1:8080\n\n')
    ..write("Press 'q' to kill server\n")
    ..write(
      'Press UP or DOWN to manipulate artificial delay by ${artificialDelayChangeAmount.inMilliseconds} ms\n\n',
    )
    ..setTextStyle()
    ..write('----------\n');

  // Start HTTP server
  await server.serve(logRequests: true);
}
