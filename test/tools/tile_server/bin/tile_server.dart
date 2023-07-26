import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:jaguar/jaguar.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> _) async {
  final console = Console()
    ..setTextStyle(bold: true, underscore: true)
    ..write('\nFMTC Testing Tile Server\n\n')
    ..setTextStyle();

  final execPath = p.split(Platform.script.toFilePath());
  final staticPath =
      p.joinAll([...execPath.getRange(0, execPath.length - 2), 'static']);

  final server = Jaguar(
    onRouteServed: (ctx) => console.writeLine(
      '[${ctx.at}] ${ctx.method} ${ctx.path}: ${ctx.response.statusCode}',
    ),
  );

  final quitHandlerRecievePort = ReceivePort();
  await Isolate.spawn(
    (_) {
      final console = Console();
      while (true) {
        if (console.readKey().char.toLowerCase() == 'q') {
          console
            ..setTextStyle(bold: true)
            ..write('Killed HTTP server\n')
            ..setTextStyle();
          Isolate.exit();
        }
      }
    },
    null,
    onExit: quitHandlerRecievePort.sendPort,
  );
  unawaited(
    quitHandlerRecievePort.first.then((_) {
      server.close();
      exit(0);
    }),
  );

  server
    ..get('/ok', (context) => 'OK!')
    ..staticFile('*', p.join(staticPath, 'assets', 'fake_tile.png'));

  console
    ..setTextStyle(italic: true)
    ..write('Now serving at 0.0.0.0:8080\n')
    ..write("Press 'q' to kill server\n\n")
    ..setTextStyle()
    ..write('GET request any path to be served a 256x256 PNG map tile\n')
    ..write("GET request '/ok' to be server a basic text response\n\n")
    ..write('-----\n\n');

  await server.serve(logRequests: true);
}
