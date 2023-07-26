// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:jaguar/jaguar.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> _) async {
  final console = Console()
    ..hideCursor()
    ..setTextStyle(bold: true, underscore: true)
    ..write('\nFMTC Testing Tile Server\n')
    ..setTextStyle()
    ..write('© Luka S (JaffaKetchup)\n')
    ..write(
      "Miniature fake tile server designed to test FMTC's throughput and download speeds\n\n",
    );

  final execPath = p.split(Platform.script.toFilePath());
  final staticPath =
      p.joinAll([...execPath.getRange(0, execPath.length - 2), 'static']);

  final requestTimestamps = <DateTime>[];
  var lastRate = 0;
  Timer.periodic(const Duration(seconds: 1), (_) {
    lastRate = requestTimestamps.length;
    requestTimestamps.clear();
  });

  const artificialDelayChangeAmount = Duration(milliseconds: 5);
  Duration currentArtificialDelay = Duration.zero;

  final server = Jaguar(
    multiThread: true,
    onRouteServed: (ctx) {
      final requestTime = ctx.at;
      requestTimestamps.add(requestTime);
      console.write(
        '[$requestTime] ${ctx.method} ${ctx.path}: ${ctx.response.statusCode}\t\t$lastRate tps  -  ${currentArtificialDelay.inMilliseconds} ms delay\n',
      );
    },
  );

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
        currentArtificialDelay += artificialDelayChangeAmount * message,
    onDone: () {
      console
        ..setTextStyle(bold: true)
        ..write('\n\nKilled HTTP server\n')
        ..setTextStyle()
        ..showCursor();
      server.close();
      exit(0);
    },
  );

  final response = ByteResponse(
    body: File(p.join(staticPath, 'assets', 'fake_tile.png')).readAsBytesSync(),
    mimeType: MimeTypes.png,
  );
  server.get(
    '*',
    (_) async {
      if (currentArtificialDelay > Duration.zero) {
        await Future.delayed(currentArtificialDelay);
      }
      return response;
    },
  );

  console
    ..setTextStyle(italic: true)
    ..write('Now serving tiles to all requests to 0.0.0.0:8080\n\n')
    ..write("Press 'q' to kill server\n")
    ..write(
      'Press UP or DOWN to manipulate artificial delay by ${artificialDelayChangeAmount.inMilliseconds} ms\n\n',
    )
    ..setTextStyle()
    ..write('----------\n');

  await server.serve(logRequests: true);
}
