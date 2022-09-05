import 'dart:math';

import 'package:intl/intl.dart';

extension SizeFormatter on num {
  String get asReadableSize {
    if (this <= 0) return '0 B';
    final List<String> units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
    final int digitGroups = log(this) ~/ log(1024);
    return '${NumberFormat('#,##0.#').format(this / pow(1024, digitGroups))} ${units[digitGroups]}';
  }
}
