import 'dart:math';
import 'package:meta/meta.dart';

export 'publicMisc.dart';

//! TYPEDEFS !//

@internal
extension ListExtensionsE<E> on List<E> {
  List<List<E>> chunked(int size) {
    List<List<E>> chunks = [];

    for (var i = 0; i < length; i += size)
      chunks.add(this.sublist(i, (i + size < length) ? i + size : length));

    return chunks;
  }
}

@internal
extension ListExtensionsDouble on List<double> {
  double get minNum => this.reduce(min);
  double get maxNum => this.reduce(max);
}

//! FUNCTIONS !//

@internal
String safeFilename(String original) =>
    original.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ');
