// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract base class BackendStore<T extends Iterable<BackendTile<dynamic>>> {
  abstract String name;
  abstract int hits;
  abstract int misses;
  T get tiles;

  /// Uses [name] for equality comparisons only (unless the two objects are
  /// [identical])
  ///
  /// Overriding this in an implementation may cause FMTC logic to break, and is
  /// therefore not recommended.
  @override
  @nonVirtual
  bool operator ==(Object? other) =>
      identical(this, other) || (other is BackendStore && name == other.name);

  @override
  @nonVirtual
  int get hashCode => name.hashCode;
}

abstract base class BackendTile<S extends Iterable<BackendStore<dynamic>>> {
  abstract String url;
  abstract DateTime lastModified;
  abstract Uint8List bytes;
  S get stores;

  /// Uses [url] for equality comparisons only (unless the two objects are
  /// [identical])
  ///
  /// Overriding this in an implementation may cause FMTC logic to break, and is
  /// therefore not recommended.
  @override
  @nonVirtual
  bool operator ==(Object? other) =>
      identical(this, other) || (other is BackendTile && url == other.url);

  @override
  @nonVirtual
  int get hashCode => url.hashCode;
}
