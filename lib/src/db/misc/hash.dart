import 'package:isar/isar.dart';

/// Efficiently converts a string into an ID for a [Collection]
int databaseHash(String string) {
  // ignore: avoid_js_rounded_ints
  int hash = 0xcbf29ce484222325;
  int i = 0;

  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
