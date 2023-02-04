// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

@internal
extension DirectoryExtensions on Directory {
  String operator >(String sub) => p.join(
        absolute.path,
        sub,
      );

  Directory operator >>(String sub) => Directory(
        p.join(
          absolute.path,
          sub,
        ),
      );

  File operator >>>(String name) => File(
        p.join(
          absolute.path,
          name,
        ),
      );
}
