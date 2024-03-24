// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:path/path.dart' as p;

const staticFilesInfo = [
  (name: 'sea', extension: 'png'),
  (name: 'land', extension: 'png'),
  (name: 'favicon', extension: 'ico'),
];

void main(List<String> _) {
  final execPath = p.split(Platform.script.toFilePath());
  final staticPath =
      p.joinAll([...execPath.getRange(0, execPath.length - 2), 'static']);

  Directory(p.join(staticPath, 'generated')).createSync();

  for (final staticFile in staticFilesInfo) {
    final dartFile = File(
      p.join(
        staticPath,
        'generated',
        '${staticFile.name}.dart',
      ),
    );
    final imageFile = File(
      p.join(
        staticPath,
        'source',
        'images',
        '${staticFile.name}.${staticFile.extension}',
      ),
    );

    dartFile.writeAsStringSync(
      'final ${staticFile.name}TileBytes = ${imageFile.readAsBytesSync()};\n',
    );
  }
}
