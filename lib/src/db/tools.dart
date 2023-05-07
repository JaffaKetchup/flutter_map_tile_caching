// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../../flutter_map_tile_caching.dart';
import 'defs/store_descriptor.dart';

@internal
class DatabaseTools {
  static int hash(String string) {
    final str = string.trim();

    // ignore: avoid_js_rounded_ints
    int hash = 0xcbf29ce484222325;
    int i = 0;

    while (i < str.length) {
      final codeUnit = str.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }
}

@internal
extension IsarExts on Isar {
  Future<DbStoreDescriptor> get descriptor async {
    final descriptor = await storeDescriptor.get(0);
    if (descriptor == null) {
      throw FMTCDamagedStoreException(
        'Failed to perform an operation on a store due to the core descriptor being missing.',
        FMTCDamagedStoreExceptionType.missingStoreDescriptor,
      );
    }
    return descriptor;
  }

  DbStoreDescriptor get descriptorSync {
    final descriptor = storeDescriptor.getSync(0);
    if (descriptor == null) {
      throw FMTCDamagedStoreException(
        'Failed to perform an operation on a store due to the core descriptor being missing.',
        FMTCDamagedStoreExceptionType.missingStoreDescriptor,
      );
    }
    return descriptor;
  }
}
