import 'dart:io';

import 'package:path/path.dart' as p;

extension DirectoryExtensions on Directory {
  Directory operator >(Directory sub) => Directory(p.join(
        absolute.path,
        sub.absolute.path,
      ));
  Directory operator >>(String sub) => Directory(p.join(
        absolute.path,
        sub,
      ));

  File operator >>>(String name) => File(p.join(
        absolute.path,
        name,
      ));
}

extension IterableNumExts on Iterable<num> {
  num get sum => reduce((v, e) => v + e);
}
