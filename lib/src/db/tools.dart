import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

@internal
class DatabaseTools {
  /// Efficiently converts a string into an ID for a [Collection]
  static int hash(String string) {
    final str = string.trim();

    // ignore: avoid_js_rounded_ints
    int hash = 0xcbf29ce484222325;
    int i = 0;

    while (i < str.length) {
      final codeUnit = str.codeUnitAt(i++);
      print('$str: $codeUnit - ${String.fromCharCode(codeUnit)}');
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    print('$str: $hash');
    print('-----------');
    return hash;
  }
}
